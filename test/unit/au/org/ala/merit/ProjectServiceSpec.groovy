package au.org.ala.merit

import au.org.ala.fieldcapture.ActivityService
import au.org.ala.fieldcapture.MetadataService
import au.org.ala.fieldcapture.UserService
import au.org.ala.fieldcapture.WebService
import grails.test.mixin.TestFor
import org.joda.time.Period
import spock.lang.Specification
import static au.org.ala.merit.ProjectService.*

/**
 * Tests the ProjectService class.
 */
@TestFor(ProjectService)
class ProjectServiceSpec extends Specification {

    WebService webService = Stub(WebService)
    ReportService reportService = Stub(ReportService)
    UserService userService = Stub(UserService)
    MetadataService metadataService = Stub(MetadataService)

    def setup() {
        service.webService = webService
        service.activityService = new ActivityService() // This is used to generate activity descriptions.
        service.grailsApplication = [config:[ecodata:[baseUrl:'']]]
        service.reportService = reportService
        service.userService = userService
        service.metadataService = metadataService
        userService.userIsAlaOrFcAdmin() >> false
        metadataService.getProgramConfiguration(_,_) >> [reportingPeriod:6, reportingPeriodAlignedToCalendar: true, weekDaysToCompleteReport:43]
    }

    def "generate reports with 3 monthly period"() {

        given:
        def projectId = 'project1'
        def start = '2014-01-01T00:00:00Z'
        def end = '2014-12-29T00:00:00Z'

        def config = [[type:'t1', period: Period.months(3)]]
        webService.getJson(_) >> [projectId:projectId, plannedStartDate:start, plannedEndDate:end]

        when:
        def result = service.regenerateReportingActivitiesForProject(projectId, config)

        then:
        result.create.size() == 4
        result.delete.size() == 0
        def activities = result.create
        activities.size() == 4
        activities[0].plannedStartDate == '2014-01-01T00:00:00Z'
        activities[0].plannedEndDate == '2014-03-31T00:00:00Z'
        activities[0].type == 't1'
        activities[0].projectId == projectId
        activities[0].description == 't1 (Jan - Mar 2014)'
        activities[1].plannedStartDate == '2014-04-01T00:00:00Z'
        activities[1].plannedEndDate == '2014-06-30T00:00:00Z'
        activities[1].type == 't1'
        activities[1].projectId == projectId
        activities[1].description == 't1 (Apr - Jun 2014)'
        activities[2].plannedStartDate == '2014-07-01T00:00:00Z'
        activities[2].plannedEndDate == '2014-09-30T00:00:00Z'
        activities[2].type == 't1'
        activities[2].projectId == projectId
        activities[2].description == 't1 (Jul - Sep 2014)'
        activities[3].plannedStartDate == '2014-10-01T00:00:00Z'
        activities[3].plannedEndDate == '2014-12-29T00:00:00Z'  // Last activity end date should not be after the project end date.
        activities[3].type == 't1'
        activities[3].projectId == projectId
        activities[3].description == 't1 (Oct - Dec 2014)'

    }

    def "generate reports with 1 monthly period"() {

        given:
        def projectId = 'project1'
        def start = '2014-01-01T00:00:00Z'
        def end = '2014-06-30T00:00:00Z'

        def config = [[type:'t1', period: Period.months(1)]]
        webService.getJson(_) >> [projectId:projectId, plannedStartDate:start, plannedEndDate:end]

        when:
        def result = service.regenerateReportingActivitiesForProject(projectId, config)

        then:
        result.create.size() == 6
        result.delete.size() == 0
        def activities = result.create
        activities[0].plannedStartDate == '2014-01-01T00:00:00Z'
        activities[0].plannedEndDate == '2014-01-31T00:00:00Z'
        activities[0].type == 't1'
        activities[0].projectId == projectId
        activities[0].description == 't1 (Jan 2014)'
        activities[5].plannedStartDate == '2014-06-01T00:00:00Z'
        activities[5].plannedEndDate == '2014-06-30T00:00:00Z'
        activities[5].type == 't1'
        activities[5].projectId == projectId
        activities[5].description == 't1 (Jun 2014)'

    }

    def "activities should not be created in periods that already have them"() {
        given:
        def projectId = 'project1'
        def start = '2014-01-01T00:00:00Z'
        def end = '2014-06-30T00:00:00Z'
        def existingActivities = [[type:'t1', plannedStartDate: '2014-01-05T00:00:00Z', plannedEndDate:'2014-01-25T00:00:00Z'],
                                  [type:'t2', plannedStartDate: '2014-02-05T00:00:00Z', plannedEndDate:'2014-02-25T00:00:00Z'],
                                  [type:'t1', plannedStartDate: '2014-05-05T00:00:00Z', plannedEndDate:'2014-05-25T00:00:00Z']]

        def config = [[type:'t1', period: Period.months(1)]]
        webService.getJson(_) >> [projectId:projectId, plannedStartDate:start, plannedEndDate:end, activities:existingActivities]

        when:
        def result = service.regenerateReportingActivitiesForProject(projectId, config)

        then:
        result.create.size() == 4
        result.delete.size() == 0
        def activities = result.create
        activities.size() == 4
        activities[0].plannedStartDate == '2014-02-01T00:00:00Z'
        activities[0].plannedEndDate == '2014-02-28T00:00:00Z'
        activities[0].type == 't1'
        activities[0].projectId == projectId
        activities[0].description == 't1 (Feb 2014)'
        activities[1].plannedStartDate == '2014-03-01T00:00:00Z'
        activities[1].plannedEndDate == '2014-03-31T00:00:00Z'
        activities[1].type == 't1'
        activities[1].projectId == projectId
        activities[1].description == 't1 (Mar 2014)'
        activities[2].plannedStartDate == '2014-04-01T00:00:00Z'
        activities[2].plannedEndDate == '2014-04-30T00:00:00Z'
        activities[2].type == 't1'
        activities[2].projectId == projectId
        activities[2].description == 't1 (Apr 2014)'
        activities[3].plannedStartDate == '2014-06-01T00:00:00Z'
        activities[3].plannedEndDate == '2014-06-30T00:00:00Z'
        activities[3].type == 't1'
        activities[3].projectId == projectId
        activities[3].description == 't1 (Jun 2014)'


    }

    def "plan should not be submitted if it's already been submitted."(){
        given:
        def projectId = 'project1'
        def planStatus = PLAN_SUBMITTED
        webService.getJson(_) >> [projectId:projectId, planStatus:planStatus]

        when:
        def result = service.submitPlan(projectId)

        then:
        result.error == "Invalid plan status"
    }


    def "plan should not be approved if it's already been approved."(){
        given:
        def projectId = 'project1'
        def planStatus = PLAN_APPROVED
        webService.getJson(_) >> [projectId:projectId, planStatus:planStatus]

        when:
        def result = service.approvePlan(projectId)

        then:
        result.error == "Invalid plan status"
    }

    def "plan should not be rejected if it's not been approved."(){
        given:
        def projectId = 'project1'
        def planStatus = PLAN_NOT_APPROVED
        webService.getJson(_) >> [projectId:projectId, planStatus:planStatus]

        when:
        def result = service.rejectPlan(projectId)

        then:
        result.error == "Invalid plan status"
    }

    def "a project's start date cannot be changed if the project has a submitted MERI plan"() {
        given:
        def projectId = 'project1'
        def newStartDate = '2015-06-01T00:00Z'
        reportService.includesSubmittedOrApprovedReports(_) >> false
        reportService.getReportsForProject(_) >> []
        webService.getJson(_) >> [projectId:projectId, planStatus:PLAN_SUBMITTED, plannedStartDate: '2015-07-01T00:00Z']

        when:
        def result = service.changeProjectStartDate(projectId, newStartDate, false)

        then:
        result.error != null
    }

    def "a project's start date cannot be changed if the project has an approved MERI plan"() {
        given:
        def projectId = 'project1'
        def newStartDate = '2015-06-01T00:00Z'
        reportService.includesSubmittedOrApprovedReports(_) >> false
        reportService.getReportsForProject(_) >> []
        webService.getJson(_) >> [projectId:projectId, planStatus:PLAN_APPROVED, plannedStartDate: '2015-07-01T00:00Z']

        when:
        def result = service.changeProjectStartDate(projectId, newStartDate, false)

        then:
        result.error != null
    }

    def "a project's start date cannot be changed if the project has a submitted or approved report"() {
        given:
        def projectId = 'project1'
        def newStartDate = '2015-06-01T00:00Z'
        reportService.includesSubmittedOrApprovedReports(_) >> true
        reportService.getReportsForProject(_) >> [[publicationStatus:ReportService.REPORT_APPROVED]]
        webService.getJson(_) >> [projectId:projectId, planStatus:PLAN_NOT_APPROVED, plannedStartDate: '2015-07-01T00:00Z', plannedEndDate:'2016-12-31T00:00Z']

        when:
        def result = service.changeProjectStartDate(projectId, newStartDate, false)

        then:
        result.error != null
    }

    def "a project's end date cannot be changed to fall within a period containing a submitted or approved report"() {
        given:
        def projectId = 'project1'
        def newStartDate = '2015-07-01T00:00Z'
        reportService.includesSubmittedOrApprovedReports(_) >> true
        reportService.getReportsForProject(_) >> [[publicationStatus:ReportService.REPORT_APPROVED]]
        webService.getJson(_) >> [projectId:projectId, planStatus:PLAN_NOT_APPROVED, plannedStartDate: '2015-07-01T00:00Z', plannedEndDate:'2016-12-31T00:00Z']
        webService.doPost(_, _) >> [resp:[status:200]]
        when:
        def result = service.changeProjectStartDate(projectId, newStartDate, false)

        then:
        result.error != null
    }

}
