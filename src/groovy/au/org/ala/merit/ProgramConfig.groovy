package au.org.ala.merit

import au.org.ala.merit.reports.ReportConfig
import org.apache.log4j.Logger

/**
 * Manages the various configuration points that a project can use to specify behaviour.
 * Currently the configuration of a project is owned by the projects program.
 */
class ProgramConfig implements Map {

    public static final String PLAN_SUBMITTED_EMAIL_TEMPLATE_CONFIG_ITEM = "planSubmittedEmailTemplate"
    public static final String PLAN_APPROVED_EMAIL_TEMPLATE_CONFIG_ITEM = "planApprovedEmailTemplate"
    public static final String PLAN_RETURNED_EMAIL_TEMPLATE_CONFIG_ITEM = "planReturnedEmailTemplate"
    public static final String REPORT_SUBMITTED_EMAIL_TEMPLATE_CONFIG_ITEM = "reportSubmittedEmailTemplate"
    public static final String REPORT_APPROVED_EMAIL_TEMPLATE_CONFIG_ITEM = "reportApprovedEmailTemplate"
    public static final String REPORT_RETURNED_EMAIL_TEMPLATE_CONFIG_ITEM = "reportReturnedEmailTemplate"

    private Logger log = Logger.getLogger(ProgramConfig.class)

    /** Items that can be omitted or included in the default project view */
    enum OptionalContent { MERI_PLAN, RISKS_AND_THREATS }

    /** Different project views */
    enum ProjectTemplate {
        ESP,
        RLP,
        DEFAULT
    }

    @Delegate Map config

    ProgramConfig(Map config) {
        this.config = new HashMap(config)
    }

    ProjectTemplate getProjectTemplate() {
        ProjectTemplate template = ProjectTemplate.DEFAULT
        if (config.projectTemplate) {
            template = ProjectTemplate.valueOf(config.projectTemplate)

            if (!template) {
                log.warn("Invalid projectTemplate specified in configuration: "+config.projectTemplate+". Using default")
                template = ProjectTemplate.DEFAULT
            }
        }
        template
    }

    EmailTemplate getPlanSubmittedTemplate() {
        emailTemplateWithDefault(PLAN_SUBMITTED_EMAIL_TEMPLATE_CONFIG_ITEM, EmailTemplate.DEFAULT_PLAN_SUBMITTED_EMAIL_TEMPLATE)
    }

    EmailTemplate getPlanApprovedTemplate() {
        emailTemplateWithDefault(PLAN_APPROVED_EMAIL_TEMPLATE_CONFIG_ITEM, EmailTemplate.DEFAULT_PLAN_APPROVED_EMAIL_TEMPLATE)
    }

    EmailTemplate getPlanReturnedTemplate() {
        emailTemplateWithDefault(PLAN_RETURNED_EMAIL_TEMPLATE_CONFIG_ITEM, EmailTemplate.DEFAULT_PLAN_RETURNED_EMAIL_TEMPLATE)
    }

    EmailTemplate getReportSubmittedTemplate() {
        emailTemplateWithDefault(REPORT_SUBMITTED_EMAIL_TEMPLATE_CONFIG_ITEM, EmailTemplate.DEFAULT_REPORT_SUBMITTED_EMAIL_TEMPLATE)
    }

    EmailTemplate getReportApprovedTemplate() {
        emailTemplateWithDefault(REPORT_APPROVED_EMAIL_TEMPLATE_CONFIG_ITEM, EmailTemplate.DEFAULT_REPORT_APPROVED_EMAIL_TEMPLATE)
    }

    EmailTemplate getReportReturnedTemplate() {
        emailTemplateWithDefault(REPORT_RETURNED_EMAIL_TEMPLATE_CONFIG_ITEM, EmailTemplate.DEFAULT_REPORT_RETURNED_EMAIL_TEMPLATE)
    }

    private EmailTemplate emailTemplateWithDefault(String name, EmailTemplate defaultTemplate) {
        if (!config.emailTemplates || !config.emailTemplates[name]) {
            return defaultTemplate
        }
        EmailTemplate emailTemplate = EmailTemplate.valueOf(config.emailTemplates[name].toUpperCase())
        if (!emailTemplate) {
            log.warn("Invalid emailTemplate specified in configuration: "+name+". Using default")
            emailTemplate = defaultTemplate
        }
        emailTemplate
    }




    boolean projectsMustStartAndEndOnContractDates

    String projectTemplate


    List<String> activityTypes
    String speciesConfiguration

    // Weird rules for generating reports.

    // 1. Milestone report for every "reporting period"
    // 1. Annual report for every year
    // 1. Short term report at end of project for duration < 3 years
    // 1. Medium term report at end of project for duration > 3 years
    List<ReportConfig> reportConfig

    boolean activitiesRequireLocking
    String activityNavigationMode // stay on page or return

}


