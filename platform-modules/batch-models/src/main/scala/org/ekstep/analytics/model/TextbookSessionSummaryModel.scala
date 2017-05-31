package org.ekstep.analytics.model

import scala.collection.mutable.HashMap
import org.ekstep.analytics.framework._
import org.apache.spark.SparkContext
import org.apache.spark.rdd.RDD
import org.ekstep.analytics.framework.util.JSONUtils
import org.ekstep.analytics.framework.util.CommonUtil
import org.ekstep.analytics.util.SessionBatchModel
import org.ekstep.analytics.creation.model.CreationEvent
import org.apache.spark.HashPartitioner
import scala.collection.mutable.Buffer
import org.ekstep.analytics.framework.util.CommonUtil
/**
 * @author yuva
 */
case class UnitSummary(total_units_added: Long, total_units_deleted: Long, total_units_modified: Long)
case class LessonSummary(total_lessons_added: Long, total_lessons_deleted: Long, total_lessons_modified: Long)
case class TextbookSessionMetrics(uid: String, sid: String, content_id: String, start_time: Long, end_time: Long, time_spent: Double, time_diff: Double, unit_summary: UnitSummary, sub_unit_summary: LessonSummary, date_range: DtRange) extends Output with AlgoOutput
case class Sessions(creationEvent: Buffer[CreationEvent]) extends AlgoInput
/**
 * @dataproduct
 * @Summarizer
 *
 * TextbookSessionSummaryModel
 *
 * Functionality
 * Compute session wise Textbook summary : Units and Lessons added/deleted/modified
 */
object TextbookSessionSummaryModel extends IBatchModelTemplate[CreationEvent, Sessions, TextbookSessionMetrics, MeasuredEvent] with Serializable {
    implicit val className = "org.ekstep.analytics.model.TextbookSessionSummaryModel"
    override def name(): String = "TextbookSessionSummaryModel";
    override def preProcess(data: RDD[CreationEvent], config: Map[String, AnyRef])(implicit sc: SparkContext): RDD[Sessions] = {
        /*
         * Input raw telemetry
         * */
        val dataToBuffer = data.filter { x => (x.edata.eks.env != null) }.collect().toBuffer
        val sortedEvent = dataToBuffer.sortBy { x => x.ets }
        val sessions = getSessions(sortedEvent)
        sc.parallelize(sessions).map { x => Sessions(x) }
    }

    override def algorithm(data: RDD[Sessions], config: Map[String, AnyRef])(implicit sc: SparkContext): RDD[TextbookSessionMetrics] = {
        val idleTime = config.getOrElse("idleTime", 600).asInstanceOf[Int];
        data.map { x =>
            val start_time = x.creationEvent.head.ets
            val end_time = x.creationEvent.last.ets
            val date_range = DtRange(start_time, end_time)
            var tmpLastEvent: CreationEvent = null;
            val eventsWithTs = x.creationEvent.map { x =>
                if (tmpLastEvent == null) tmpLastEvent = x;
                val ts = CommonUtil.getTimeDiff(tmpLastEvent.ets, x.ets).get;
                tmpLastEvent = x;
                (x, if (ts > idleTime) 0 else ts)
            }
            val time_spent = CommonUtil.roundDouble(eventsWithTs.map(f => f._2).sum, 2);
            val time_diff = CommonUtil.roundDouble(CommonUtil.getTimeDiff(start_time, end_time).get, 2);
            val uid = x.creationEvent.head.uid
            val sid = x.creationEvent.head.context.get.sid
            val content_id = x.creationEvent.head.context.get.content_id
            val filtered_events = x.creationEvent.filter { x => (x.edata.eks.`type`.equals("action") && (x.edata.eks.target.equals("") || x.edata.eks.target.equals("textbookunit")) && x.edata.eks.subtype.equals("save") && x.edata.eks.values.size > 0) }
            val buffered_events = filtered_events.map { x =>
                x.edata.eks.values.get
            }.flatMap { x => x }
            val total_units_added = buffered_events.map { x => x.getOrElse("unit_added", "0").toString().toLong }.sum
            val total_units_deleted = buffered_events.map { x => x.getOrElse("unit_deleted", "0").toString().toLong }.sum
            val total_units_modified = buffered_events.map { x => x.getOrElse("unit_modified", "0").toString().toLong }.sum
            val total_lessons_added = buffered_events.map { x => x.getOrElse("lesson_added", "0").toString().toLong }.sum
            val total_lessons_deleted = buffered_events.map { x => x.getOrElse("lesson_deleted", "0").toString().toLong }.sum
            val total_lessons_modified = buffered_events.map { x => x.getOrElse("lesson_modified", "0").toString().toLong }.sum
            TextbookSessionMetrics(uid, sid, content_id, start_time, end_time, time_spent, time_diff, UnitSummary(total_units_added, total_units_deleted, total_units_modified), LessonSummary(total_lessons_added, total_lessons_deleted, total_lessons_modified), date_range)
        }
    }

    override def postProcess(data: RDD[TextbookSessionMetrics], config: Map[String, AnyRef])(implicit sc: SparkContext): RDD[MeasuredEvent] = {
        data.map { summary =>
            val mid = CommonUtil.getMessageId("ME_TEXTBOOK_SESSION_SUMMARY", summary.sid + summary.content_id + summary.uid, config.getOrElse("granularity", "DAY").asInstanceOf[String], summary.start_time);
            val measures = Map(
                "start_time" -> summary.start_time,
                "end_time" -> summary.end_time,
                "time_spent" -> summary.time_spent,
                "time_diff" -> summary.time_diff,
                "unit_summary" -> summary.unit_summary,
                "lesson_summary" -> summary.sub_unit_summary,
                "date_range" -> summary.date_range);
            val pdata = PData(config.getOrElse("producerId", "AnalyticsDataPipeline").asInstanceOf[String], config.getOrElse("modelId", "TextbookSessionSummarizer").asInstanceOf[String], config.getOrElse("modelVersion", "1.0").asInstanceOf[String]);
            MeasuredEvent("ME_TEXTBOOK_SESSION_SUMMARY", System.currentTimeMillis(), 0L, "1.0", mid, summary.uid, None, None,
                Context(pdata, None, "DAY", summary.date_range),
                Dimensions(Option(summary.uid), None, None, None, None, None, None, None, None, None, None, Option(summary.content_id), None, None, Option(summary.sid), None), MEEdata(measures), None);
        };
    }

    /*
     * Sessionization based on Env
     * */
    private def getSessions(creationEvent: Buffer[CreationEvent]): Buffer[Buffer[CreationEvent]] = {
        var sessions = Buffer[Buffer[CreationEvent]]();
        var tmpArr = Buffer[CreationEvent]();
        var prevEnv = ""
        creationEvent.foreach { x =>
            if ((prevEnv.equals("textbook") && prevEnv.equals(x.edata.eks.env)) && (CommonUtil.getTimeDiff(tmpArr.last.ets, x.ets).get / 60 < 30)) {
                tmpArr += x
            } else {
                if (tmpArr.length > 0 && prevEnv.equals("textbook"))
                    sessions += tmpArr
                tmpArr = Buffer[CreationEvent]();
                tmpArr += x
            }
            prevEnv = x.edata.eks.env
        }
        if (sessions.length <= 0 && prevEnv.equals("textbook"))
            sessions += tmpArr
        sessions
    }
}