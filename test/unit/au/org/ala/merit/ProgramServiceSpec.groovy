package au.org.ala.merit

import grails.test.mixin.TestFor
import spock.lang.Specification

@TestFor(ProgramService)
class ProgramServiceSpec extends Specification {

    ReportService reportService = Mock(ReportService)
    WebService webService = Mock(WebService)
    DocumentService documentService = Mock(DocumentService)
    UserService userService = Mock(UserService)

    def setup() {
        service.reportService = reportService
        service.webService = webService
        service.documentService = documentService
        service.userService = userService
    }

    def "when a report is submitted, the program service should setup and delegate to the report service"() {

        setup:
        String programId = 'p1'
        String reportId = 'r1'
        Map program = [programId:programId, name:"Program"]
        Map report = [reportId:reportId, activityId:'a1']
        List roles = []

        when:
        service.submitReport(programId, reportId)

        then:
        1 * webService.getJson({it.endsWith("/program/$programId")}) >> program
        1 * userService.getMembersOfProgram(programId) >> [members:roles]
        1 * reportService.get(reportId) >> report
        1 * reportService.submitReport(reportId, [report.activityId], program, [],  EmailTemplate.RLP_CORE_SERVCIES_REPORT_SUBMITTED_EMAIL_TEMPLATE)
    }

    def "when a report is approved, the program service should setup and delegate to the report service"() {

        setup:
        String programId = 'p1'
        String reportId = 'r1'
        Map program = [programId:programId, name:"Program"]
        Map report = [reportId:reportId, activityId:'a1']
        List roles = []
        String reason = 'r1'

        when:
        service.approveReport(programId, reportId, reason)

        then:
        1 * webService.getJson({it.endsWith("/program/$programId")}) >> program
        1 * userService.getMembersOfProgram(programId) >> [members:roles]
        1 * reportService.get(reportId) >> report
        1 * reportService.approveReport(reportId, [report.activityId], reason, program, [],  EmailTemplate.RLP_CORE_SERVICES_REPORT_APPROVED_EMAIL_TEMPLATE)
    }

    def "when a report is returned, the program service should setup and delegate to the report service"() {

        setup:
        String programId = 'p1'
        String reportId = 'r1'
        Map program = [programId:programId, name:"Program"]
        Map report = [reportId:reportId, activityId:'a1']
        List roles = []
        String reason = 'r1'

        when:
        service.rejectReport(programId, reportId, reason, 'unused')

        then:
        1 * webService.getJson({it.endsWith("/program/$programId")}) >> program
        1 * userService.getMembersOfProgram(programId) >> [members:roles]
        1 * reportService.get(reportId) >> report
        1 * reportService.rejectReport(reportId, [report.activityId], reason, program, [],  EmailTemplate.RLP_CORE_SERVICES_REPORT_RETURNED_EMAIL_TEMPLATE)
    }

}