package org.ekstep.analytics.job

import org.apache.spark.SparkContext
import org.apache.spark.sql.functions.{col, _}
import org.apache.spark.sql.types.DataTypes
import org.apache.spark.sql.{DataFrame, SparkSession}
import org.ekstep.analytics.framework._
import org.ekstep.analytics.framework.util.{CommonUtil, JSONUtils, JobLogger}
import org.sunbird.cloud.storage.conf.AppConf
import scala.collection.{Map, _}

trait Reporter {
  def fetchTable(spark: SparkSession, settings: Map[String, String]): DataFrame

  def prepareReport(spark: SparkSession, fetchTable: (SparkSession, Map[String, String]) => DataFrame): DataFrame

  def saveReportES(reportDF: DataFrame): Unit

  def uploadReport(reportDF: DataFrame, url: String): Unit
}

object CourseMetricsJob extends optional.Application with IJob with Reporter {

  implicit val className = "org.ekstep.analytics.updater.UpdateCourseMetrics"

  def name(): String = "UpdateCourseMetrics"

  def main(config: String)(implicit sc: Option[SparkContext] = None) {

    JobLogger.init("DataExhaustJob")
    JobLogger.start("DataExhaust Job Started executing", Option(Map("config" -> config, "model" -> name)))
    val jobConfig = JSONUtils.deserialize[JobConfig](config);

    if (null == sc.orNull) {
      JobContext.parallelization = 10
      implicit val sparkContext = CommonUtil.getSparkContext(JobContext.parallelization, jobConfig.appName.getOrElse(jobConfig.model))
      try {
        execute(jobConfig)
      } finally {
        CommonUtil.closeSparkContext()
      }
    } else {
      implicit val sparkContext: SparkContext = sc.orNull
      execute(jobConfig)
    }
  }

  private def execute(config: JobConfig)(implicit sc: SparkContext) = {
    val accName = AppConf.getStorageKey("azure")
    val courseMetricsContainer = AppConf.getConfig("course.metrics.azure.container")

    val url = s"wasbs://$courseMetricsContainer@$accName.blob.core.windows.net/reports"

    val sparkConf = sc.getConf
      .set("es.write.operation", "upsert")

    val spark = SparkSession.builder.config(sparkConf).getOrCreate()
    val reportDF = prepareReport(spark, fetchTable)
    uploadReport(reportDF, url)
    saveReportES(reportDF)
  }

  def fetchTable(spark: SparkSession, settings: Map[String, String]): DataFrame = {
    spark
      .read
      .format("org.apache.spark.sql.cassandra")
      .options(settings)
      .load()
  }

  def prepareReport(spark: SparkSession, fetchTable: (SparkSession, Map[String, String]) => DataFrame): DataFrame = {
    val sunbirdKeyspace = AppConf.getConfig("course.metrics.cassandra.keyspace")
    val courseBatchDF = fetchTable(spark, Map("table" -> "course_batch", "keyspace" -> sunbirdKeyspace))
    val userCoursesDF = fetchTable(spark, Map("table" -> "user_courses", "keyspace" -> sunbirdKeyspace))
    val userDF = fetchTable(spark, Map("table" -> "user", "keyspace" -> sunbirdKeyspace))
    val userOrgDF = fetchTable(spark, Map("table" -> "user_org", "keyspace" -> sunbirdKeyspace))
    val organisationDF = fetchTable(spark, Map("table" -> "organisation", "keyspace" -> sunbirdKeyspace))
    val locationDF = fetchTable(spark, Map("table" -> "location", "keyspace" -> sunbirdKeyspace))

    /*
    * courseBatchDF has details about the course and batch details for which we have to prepare the report
    * courseBatchDF is the primary source for the report
    * userCourseDF has details about the user details enrolled for a particular course/batch
    * */
    val userCourseDenormDF = courseBatchDF.join(userCoursesDF, userCoursesDF.col("batchid") === courseBatchDF.col("id") && lower(userCoursesDF.col("active")).equalTo("true"), "inner")
      .select(col("batchid"),
        col("userid"),
        col("leafnodescount"),
        col("progress"),
        col("enddate"),
        col("startdate"),
        col("enrolleddate"),
        col("active"),
        courseBatchDF.col("courseid"))

    /*
    *userCourseDenormDF lacks some of the user information that need to be part of the report
    *here, it will add some more user details
    * */
    val userDenormDF = userCourseDenormDF
      .join(userDF, Seq("userid"), "inner")
      .select(
        userCourseDenormDF.col("*"),
        col("firstname"),
        col("lastname"),
        col("email"),
        col("phone"),
        col("rootorgid"),
        col("locationids"))

    /*
    * userDenormDF lacks organisation details, here we are mapping each users to get the organisationids
    * */
    val userOrgDenormDF = userDenormDF
      .join(userOrgDF, userOrgDF.col("userid") === userDenormDF.col("userid") && lower(userOrgDF.col("isdeleted")).equalTo("false"), "inner")
      .select(userDenormDF.col("*"), col("organisationid"))

    val locationDenormDF = userOrgDenormDF
      .withColumn("exploded_location", explode(col("locationids")))
      .join(locationDF, col("exploded_location") === locationDF.col("id") && locationDF.col("type") === "district")
      .groupBy("userid", "exploded_location")
      .agg(concat_ws(",", collect_list(locationDF.col("name"))) as "district_name")
      .drop(col("exploded_location"))

    val userLocationResolvedDF = userOrgDenormDF
      .join(locationDenormDF, Seq("userid"), "left_outer")

    /*
    * Resolve organisation name from `rootorgid`
    * */
    val resolvedOrgNameDF = userLocationResolvedDF
      .join(organisationDF, organisationDF.col("id") === userLocationResolvedDF.col("rootorgid"))
      .select(userLocationResolvedDF.col("userid"), col("orgname").as("orgname_resolved"))

    /*
    * Resolve school name from `orgid`
    * */
    val resolvedSchoolNameDF = userLocationResolvedDF
      .join(organisationDF, organisationDF.col("id") === userLocationResolvedDF.col("organisationid"))
      .select(userLocationResolvedDF.col("userid"), col("orgname").as("schoolname_resolved"))

    val toLongUDF = udf((value: Double) => value.toLong)

    /*
    * merge orgName and schoolName based on `userid` and calculate the course progress percentage from `progress` column which is no of content visited/read
    * */
    resolvedOrgNameDF
      .join(resolvedSchoolNameDF, Seq("userid"))
      .join(userLocationResolvedDF, Seq("userid"))
      .withColumn("course_completion", toLongUDF(round(expr("progress/leafnodescount * 100"))))
      .withColumn("generatedOn", date_format(from_utc_timestamp(current_timestamp.cast(DataTypes.TimestampType), "Asia/Kolkata"), "yyyy-MM-dd'T'HH:mm:ssXXX'Z'"))
  }


  def saveReportES(reportDF: DataFrame): Unit = {

    import org.elasticsearch.spark.sql._
    val participantsCountPerBatchDF = reportDF
      .groupBy(col("batchid"))
      .agg(count("*").as("participantsCountPerBatch"))

    val courseCompletionCountPerBatchDF = reportDF
      .filter(col("course_completion").equalTo(100))
      .groupBy(col("batchid"))
      .agg(count("*").as("courseCompletionCountPerBatch"))

    val batchStatsDF = participantsCountPerBatchDF
      .join(courseCompletionCountPerBatchDF, Seq("batchid"), "left_outer")
      .join(reportDF, Seq("batchid"))
      .select(
        concat_ws(" ", col("firstname"), col("lastname")).as("name"),
        concat_ws(":", col("userid"), col("batchid")).as("id"),
        col("email").as("maskedEmail"),
        col("phone").as("maskedPhone"),
        col("orgname_resolved").as("rootOrgName"),
        col("schoolname_resolved").as("subOrgName"),
        col("startdate").as("startDate"),
        col("enddate").as("endDate"),
        col("courseid").as("courseId"),
        col("generatedOn").as("lastUpdatedOn"),
        col("batchid").as("batchId"),
        col("course_completion").as("completedPercent"),
        col("district_name").as("districtName"),
        date_format(col("enrolleddate"), "yyyy-MM-dd'T'HH:mm:ssXXX'Z'").as("enrolledOn")
      )

    var batchDetailsDF = participantsCountPerBatchDF
      .join(courseCompletionCountPerBatchDF, Seq("batchid"), "left_outer")
      .join(reportDF, Seq("batchid"))
      .groupBy(
        col("batchid").as("id"),
        col("courseCompletionCountPerBatch").as("completedCount"),
        col("participantsCountPerBatch").as("participantCount")
      )
      .count()
      .drop(col("count"))

    // fill null values with 0
    batchDetailsDF = batchDetailsDF.na.fill(0, Seq("completedCount"))
    batchDetailsDF = batchDetailsDF.na.fill(0, Seq("participantCount"))

    val cBatchStatsIndex = AppConf.getConfig("course.metrics.es.index.cbatchstats")
    val cBatchIndex = AppConf.getConfig("course.metrics.es.index.cbatch")

    //Save to sunbird platform Elasticsearch instance
    // upsert batch stats to cbatchstats index
    batchStatsDF.saveToEs(s"$cBatchStatsIndex/_doc", Map("es.mapping.id" -> "id"))

    // upsert batch details to cbatch index
    batchDetailsDF.saveToEs(s"$cBatchIndex/_doc", Map("es.mapping.id" -> "id"))
  }


  def uploadReport(reportDF: DataFrame, url: String): Unit = {

    val toPercentageStringUDF = udf((value: Double) => s"${value.toInt}%")

    val defaultProgressUDF = udf((value: String) => value match {
      case null => "100%"
      case _ => value
    })

    reportDF
      .select(
        concat_ws(" ", col("firstname"), col("lastname")).as("User Name"),
        col("batchid"),
        col("email").as("Email ID"),
        col("phone").as("Mobile Number"),
        col("district_name").as("District Name"),
        col("orgname_resolved").as("Organisation Name"),
        col("schoolname_resolved").as("School Name"),
        defaultProgressUDF(toPercentageStringUDF(col("course_completion"))).as("Course Progress"),
        col("generatedOn").as("last updated")
      )
      .coalesce(1)
      .write
      .partitionBy("batchid")
      .mode("overwrite")
      .format("com.databricks.spark.csv")
      .option("header", "true")
      .save(url)
  }
}

