package au.org.ala.merit

import au.org.ala.fieldcapture.DateUtils
import grails.converters.JSON
import org.apache.poi.ss.usermodel.Cell
import org.apache.poi.ss.usermodel.Row
import org.apache.poi.ss.usermodel.Sheet
import org.apache.poi.ss.usermodel.Workbook
import org.apache.poi.ss.usermodel.WorkbookFactory
import org.joda.time.DateTime
import org.joda.time.DateTimeZone
import org.joda.time.Interval
import org.joda.time.Period
import org.joda.time.format.DateTimeFormat

/**
 * Extends the plugin OrganisationController to support Green Army project reporting.
 */
class OrganisationController extends au.org.ala.fieldcapture.OrganisationController {

    def activityService, metadataService, projectService

    def report(String id) {

        def organisation = organisationService.get(id, 'all')
        def activityType = params.type

        def activityModel = metadataService.getActivityModel(activityType)
        def outputModels = activityModel.outputs.collect {
            [name:it, annotatedModel:metadataService.annotatedOutputDataModel(it), dataModel:metadataService.getDataModelFromOutputName(it)]
        }

        def criteria = [type:activityType, projectId:organisation.projects.collect{it.projectId}, dateProperty:'plannedEndDate', startDate:params.plannedStartDate, endDate:params.plannedEndDate]

        def activityResp = activityService.search(criteria)
        def activities = activityResp?.resp.activities

        // augment each activity with project name so we can display it.
        activities.each { activity ->
            def project = organisation.projects.find{it.projectId == activity.projectId}
            activity.projectName = project?.name
            activity.grantId = project?.grantId
            activity.externalId = project?.externalId
        }
        activities?.sort{a,b -> (a.plannedEndDate <=> b.plannedEndDate) ?: (a.grantId <=> b.grantId) ?: (a.externalId <=> b.externalId) ?: (a.activityId <=> b.activityId)}

        render view: '/activity/bulkEdit', model:[organisation:organisation, type:activityType,
                       title:activityService.defaultDescription([type:activityType, plannedStartDate:params.plannedStartDate, plannedEndDate:params.plannedEndDate]),
                       activities:activities,
                       outputModels:outputModels]
    }


    def getAdHocReportTypes(String projectId) {

        def supportedTypes = organisationService.getSupportedAdHocReports(projectId)
        render supportedTypes as JSON

    }

    def createAdHocReport() {
        def supportedTypes = organisationService.getSupportedAdHocReports(params.projectId)

        if (params.type in supportedTypes) {

            def activity = [projectId: params.projectId, type: params.type, description: params.type, plannedStartDate: params.plannedStartDate, plannedEndDate: params.plannedEndDate]

            def response = activityService.create(activity)
            if (response.resp.activityId) {
                chain(controller: 'activity', action: 'enterData', id: response.resp.activityId, params:[returnTo:params.returnTo])
            }
        }
        else {
            // Go back to where we were before.
            render ''
        }
    }

    /** Temporary method to prepopulate Green Army projects and reporting activities */
    def prepopGreenArmy() {


        def resp = projectService.search([associatedProgram:'Green Army', view:'flat'])

        if (resp?.resp?.projects) {
            def projects = resp.resp.projects
            def projectsByOrg = projects.groupBy{it.serviceProviderName}

            projectsByOrg.each{org, orgProjects ->
                if (!org) {
                    return
                }
                def reportProjectName = org+' Green Army Quarterly Reporting'
                def orgReportProject = orgProjects.find{ it.name == reportProjectName }
                if (!orgReportProject) {
                    orgReportProject = [
                            externalId:org+'-Report',
                            name:reportProjectName,
                            plannedStartDate:orgProjects.min{it.plannedStartDate}.plannedStartDate,
                            plannedEndDate:orgProjects.max{it.plannedEndDate}.plannedEndDate,
                            associatedProgram:'Green Army',
                            description:'This project is to support the reporting requirements of the Green Army Programme',
                            organisationName:org,
                            serviceProviderName:org
                    ]
                    def result = projectService.create(orgReportProject)
                    orgReportProject.projectId = result.resp.projectId

                }
                projectService.createReportingActivitiesForProject(orgReportProject.projectId, [[period: Period.months(3), type:'Green Army - Quarterly project report']])

                orgProjects.each { project ->
                    if (project.projectId == orgReportProject.projectId) {
                        return
                    }

                    projectService.createReportingActivitiesForProject(project.projectId, [[period: Period.months(1), type:'Green Army - Monthly project status report']])
                }
            }


            render projectsByOrg as JSON
        }


    }

    def importGreenArmyMonthlyReports() {

        response.setContentType('text/plain')

        def sheets = ['Jul14', 'Aug14', 'Sep14', 'Oct14', 'Nov14', 'Dec14', 'Jan15']
        if (request.respondsTo('getFile')) {
            def file = request.getFile('gaData')
            if (file) {
                Workbook workbook = WorkbookFactory.create(file.inputStream)

                for (String sheetName in sheets) {
                    println sheetName
                    println '***********************************'
                    Sheet sheet = workbook.getSheet(sheetName)

                    // The data we care about starts at row 12 (1 based)
                    int rowIndex = 11
                    Row row = sheet.getRow(rowIndex++)
                    def hasData = true
                    while (hasData) {
                        hasData = processRow(sheet, row)

                        row = sheet.getRow(rowIndex++)
                    }


                }

            }
        }
        render "done"
    }



    private def processRow(Sheet sheet, Row row) {

        def cell = row.getCell(0)

        if (cell.getCachedFormulaResultType() != Cell.CELL_TYPE_STRING) {
            return false
        }
        def projectId =  cell.getStringCellValue().substring(0, 12)

        def resp = projectService.search([grantId:projectId, view:'all'])

        def projects = resp?.resp?.projects
        if (!projects) {
            //println "No projects found with id ${projectId}\n\n"
            return true
        }
        else if (projects.size() > 1) {
            println "Muliple projects found with id ${projectId}\n\n"
            return true
        }

        def project = projects[0]

        def previouslyCompleted = row.getCell(3).getStringCellValue() == 'YES'
        if (previouslyCompleted) {
            println "Project ${projectId} previously completed\n\n"
            return true
        }


        def agreementDate = getCellValue(row, 5)

        if (agreementDate && (agreementDate instanceof Number)) {
            if (agreementDate instanceof Number) {
                def agreementDateString = excelDateToISODateString(agreementDate)

                if (project.serviceProviderAgreementDate != agreementDateString) {
                    // set the agreement date.
                    println "Setting ${projectId} agreement date to ${agreementDateString}\n"
                    projectService.update(project.projectId, [serviceProviderAgreementDate: agreementDateString])
                }
            }
        }

        def commencementDate = getCellValue(row, 7)
        def actualCommencementDate = getCellValue(row, 9)
        if ((commencementDate && (commencementDate instanceof Number) || (actualCommencementDate && actualCommencementDate instanceof Number))) {
            def commencementDateString = ''
            if (commencementDate && (commencementDate instanceof Number)) {
                commencementDateString = excelDateToISODateString(commencementDate)
            }

            def actualCommencementDateString = ''
            if (actualCommencementDate && (actualCommencementDate instanceof Number)) {
                actualCommencementDateString = excelDateToISODateString(actualCommencementDate)
            }

            def startDateString = actualCommencementDateString ?: commencementDateString

            if (startDateString != project.plannedStartDate) {
                println "Project ${projectId} actual commencement date  ${startDateString} plannedStartDate ${project.plannedStartDate}\n"

                println "****************************Updating project dates and activities!!! ${project.grantId} ${project.projectId}**********************************"


                def originalStartDate = DateUtils.parse(project.plannedStartDate)
                def originalEndDate = DateUtils.parse(project.plannedEndDate)

                def originalDuration = new Interval(originalStartDate, originalEndDate).toDuration()

                // So do we update the project date at this point?
                project.plannedStartDate = startDateString

                def startDate = DateUtils.parse(startDateString)

                def endDate = startDate.plus(originalDuration)

                project.plannedEndDate = DateUtils.format(endDate.toDateTimeISO())

                projectService.update(project.projectId, [plannedStartDate: project.plannedStartDate, plannedEndDate: project.plannedEndDate])


                // Update the dates of the works activities
                def activityIds = project.activities.findAll{it.type != 'Green Army - Monthly project status report'}.collect {it.activityId}

                activityService.bulkUpdateActivities(activityIds, [plannedStartDate: project.plannedStartDate, plannedEndDate: project.plannedEndDate])

                projectService.createReportingActivitiesForProject(project.projectId, [[period: Period.months(1), type:'Green Army - Monthly project status report']])
            }

        }



        def continuingProject = getCellValue(row, 11)
        def completed = getCellValue(row, 13)
        def onTrack = getCellValue(row, 15)


        def participantsCommenced = getCellValue(row, 17)
        def notComplete = getCellValue(row, 19)
        def completedProjects = getCellValue(row, 21)
        def commencedTraining = getCellValue(row, 23)
        def commencedNonAcceditedTraining = getCellValue(row, 25)
        if (commencedNonAcceditedTraining) {
            println "Project ${projectId} has non accredited training\n"
        }
        def exitedTraining = getCellValue(row, 27)
        def completedTraining = getCellValue(row, 29)

        def projectStatus
        if (continuingProject == 'NO') {
            projectStatus = 'Commenced'
        }
        else if (completed == 'YES') {
            projectStatus = 'Completed'
        }
        else if (onTrack == 'YES') {
            projectStatus = 'Progressing - on schedule'
        }
        else {
            projectStatus = 'Progressing - behind schedule'
        }

        def outputData = [
                trainingCommencingNonaccredited:commencedNonAcceditedTraining ?: 0,
                trainingCommencedAccredited:commencedTraining ?: 0,
                trainingNoExited:exitedTraining  ?: 0,
                totalParticipantsCompleted:completedProjects  ?: 0,
                totalParticipantsNotCompleted:notComplete  ?: 0,
                totalParticipantsCommenced:participantsCommenced  ?: 0,
                trainingNoCompleted:completedTraining  ?: 0,
                projectStatus:projectStatus
        ]
        if (continuingProject) {
            loadReportData(sheet.sheetName, project, outputData)
        }

        return true
    }

    def TAB_DATE_FORMAT =  DateTimeFormat.forPattern("MMMyy")

    private loadReportData(month, project, outputData) {

        DateTime date = TAB_DATE_FORMAT.parseDateTime(month).plusDays(1)
        Interval interval = new Interval(date, Period.months(1))
        def monthlyReports = project.activities.findAll {it.type == 'Green Army - Monthly project status report'}

        def reports = monthlyReports.findAll {
            def plannedEndDate = DateUtils.parse(it.plannedEndDate)
            return interval.contains(plannedEndDate)
        }

        if (reports.size() == 0) {
            println "No report found for project ${project.projectId}, ${project.plannedStartDate} for month ${month}"
            return
        }

        def report = reports[0]
        if (reports.size() > 1) {
            println "Multiple reports found for project ${project.projectId}, for month ${month} : ${reports.collect{it.activityId}}"
        }


        if (!report.outputs) {
            report.outputs = []
        }

        def output = report.outputs.find{it.name == 'Monthly Status Report Data'}

        if (!output) {
            output = [name:'Monthly Status Report Data', activityId:report.activityId, data:[:]]
            report.outputs << output
        }

        output.data.putAll(outputData)

        activityService.update(report.activityId, [activityId:report.activityId, progress:'finished', outputs:report.outputs])


    }


    private def getCellValue(Row row, int columnIndex) {
        Cell cell = row.getCell(columnIndex)
        if (cell.getCellType() == Cell.CELL_TYPE_BLANK) {
            return ''
        }
        if (cell.getCellType() == Cell.CELL_TYPE_STRING) {
            return cell.getStringCellValue()
        }
        if (cell.getCellType() == Cell.CELL_TYPE_NUMERIC) {
            return cell.getNumericCellValue()
        }
        if (cell.getCellType() == Cell.CELL_TYPE_FORMULA) {
            int type =  cell.getCachedFormulaResultType()
            if (type == Cell.CELL_TYPE_STRING) {
                return cell.getStringCellValue()
            }
            if (type == Cell.CELL_TYPE_NUMERIC) {
                return cell.getNumericCellValue()
            }
        }

        throw new Exception("Don't know what to do with cell of type: ${cell.getCellType()}")

    }

    private String excelDateToISODateString(date) {
        final long DAYS_FROM_1900_TO_1970 = 25569
        // In Excel, the date is number of days since 1900
        long days = date as Long
        long millisSince1970 = (days - DAYS_FROM_1900_TO_1970) * 24l * 60l * 60l * 1000l
        def dateTime = new DateTime(millisSince1970)
        dateTime = dateTime.toDateTime(DateTimeZone.UTC)
        return DateUtils.format(dateTime)
    }
}
