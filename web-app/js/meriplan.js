/*
   Script for handling Project MERI Plan
 */

function MERIPlan(project, themes, key) {
   var self = this;
   if(!project.custom){ project.custom = {};}
   if(!project.custom.details){project.custom.details = {};}

   if (key) {
       var savedProjectCustomDetails = amplify.store(key);
       if (savedProjectCustomDetails) {
          var restored = JSON.parse(savedProjectCustomDetails);
          if (restored.custom) {
             $('#restoredData').show();
             project.custom.details = restored.custom.details;
          }
       }
   }

   self.details = new DetailsViewModel(project.custom.details, getBudgetHeaders(project));
   self.detailsLastUpdated = ko.observable(project.custom.details.lastUpdated).extend({simpleDate: true});
   self.isProjectDetailsSaved = ko.computed (function (){
      return (project['custom']['details'].status == 'active');
   });
   self.isProjectDetailsLocked = ko.computed (function (){
      return (project.planStatus == 'approved' || project.planStatus =='submitted');
   });

   self.projectThemes =  $.map(themes, function(theme, i) { return theme.name; });
   self.projectThemes.push("MERI & Admin");
   self.projectThemes.push("Others");

   self.likelihoodOptions = ['Almost Certain', 'Likely', 'Possible', 'Unlikely', 'Remote'];
   self.consequenceOptions = ['Insignificant', 'Minor', 'Moderate', 'Major', 'Extreme'];
   self.ratingOptions = ['High', 'Significant', 'Medium', 'Low'];
   self.obligationOptions = ['Yes', 'No'];
   self.threatOptions = ['Blow-out in cost of project materials', 'Changes to regional boundaries affecting the project area', 'Co-investor withdrawal / investment reduction',
      'Lack of delivery partner capacity', 'Lack of delivery partner / landholder interest in project activities', 'Organisational restructure / loss of corporate knowledge', 'Organisational risk (strategic, operational, resourcing and project levels)',
      'Seasonal conditions (eg. drought, flood, etc.)', 'Timeliness of project approvals processes',
      'Workplace health & safety (eg. Project staff and / or delivery partner injury or death)', 'Land use Conflict'];
   self.organisations =['Academic/research institution', 'Australian Government Department', 'Commercial entity', 'Community group',
      'Farm/Fishing Business', 'If other, enter type', 'Indigenous Organisation', 'Individual', 'Local Government', 'Other', 'Primary Industry group',
      'School', 'State Government Organisation', 'Trust'];
   self.protectedNaturalAssests =[ 'Natural/Cultural assets managed','Threatened Species', 'Threatened Ecological Communities',
      'Migratory Species', 'Ramsar Wetland', 'World Heritage area', 'Community awareness/participation in NRM', 'Indigenous Cultural Values',
      'Indigenous Ecological Knowledge', 'Remnant Vegetation', 'Aquatic and Coastal systems including wetlands', 'Not Applicable'];

   self.addBudget = function(){
      self.details.budget.rows.push (new BudgetRowViewModel({},getBudgetHeaders(project)));
   };
   self.removeBudget = function(budget){
      self.details.budget.rows.remove(budget);
   };

   self.addObjectives = function(){
      self.details.objectives.rows.push(new GenericRowViewModel());
   };
   self.addOutcome = function(){
      self.details.objectives.rows1.push(new OutcomeRowViewModel());
   };
   self.removeObjectives = function(row){
      self.details.objectives.rows.remove(row);
   };
   self.removeObjectivesOutcome = function(row){
      self.details.objectives.rows1.remove(row);
   };
   self.addNationalAndRegionalPriorities = function(){
      self.details.priorities.rows.push(new GenericRowViewModel());
   };
   self.removeNationalAndRegionalPriorities = function(row){
      self.details.priorities.rows.remove(row);
   };

   self.addKEQ = function(){
      self.details.keq.rows.push(new GenericRowViewModel());
   };
   self.removeKEQ = function(keq){
      self.details.keq.rows.remove(keq);
   };

   self.mediaOptions = [{id:"yes",name:"Yes"},{id:"no",name:"No"}];

   self.addEvents = function(){
      self.details.events.push(new EventsRowViewModel());
   };
   self.removeEvents = function(event){
      self.details.events.remove(event);
   };

   self.addPartnership = function(){
      self.details.partnership.rows.push (new GenericRowViewModel());
   };
   self.removePartnership = function(partnership){
      self.details.partnership.rows.remove(partnership);
   };

};

function DetailsViewModel(o, period) {
   var self = this;
   self.status = ko.observable(o.status);
   self.obligations = ko.observable(o.obligations);
   self.policies = ko.observable(o.policies);
   self.caseStudy = ko.observable(o.caseStudy ? o.caseStudy : false);
   self.keq = new GenericViewModel(o.keq);
   self.objectives = new ObjectiveViewModel(o.objectives);
   self.priorities = new GenericViewModel(o.priorities);
   self.implementation = new ImplementationViewModel(o.implementation);
   self.partnership = new GenericViewModel(o.partnership);
   self.lastUpdated = o.lastUpdated ? o.lastUpdated : moment().format();
   self.budget = new BudgetViewModel(o.budget, period);

   var row = [];
   o.events ? row = o.events : row.push(ko.mapping.toJS(new EventsRowViewModel()));
   self.events = ko.observableArray($.map(row, function (obj, i) {
      return new EventsRowViewModel(obj);
   }));

   self.modelAsJSON = function() {
      var tmp = {};
      tmp['details'] =  ko.mapping.toJS(self);
      var jsData = {"custom": tmp};
      var json = JSON.stringify(jsData, function (key, value) {
         return value === undefined ? "" : value;
      });
      return json;
   };
};

function GenericViewModel(o) {
   var self = this;
   if(!o) o = {};
   self.description = ko.observable(o.description);
   var row = [];
   o.rows ? row = o.rows : row.push(ko.mapping.toJS(new GenericRowViewModel()));
   self.rows = ko.observableArray($.map(row, function (obj,i) {
      return new GenericRowViewModel(obj);
   }));
};

function GenericRowViewModel(o) {
   var self = this;
   if(!o) o = {};
   self.data1 = ko.observable(o.data1);
   self.data2 = ko.observable(o.data2);
   self.data3 = ko.observable(o.data3);
};

function ObjectiveViewModel(o) {
   var self = this;
   if(!o) o = {};

   var row = [];
   o.rows ? row = o.rows : row.push(ko.mapping.toJS(new GenericRowViewModel()));
   self.rows = ko.observableArray($.map(row, function (obj, i) {
      return new GenericRowViewModel(obj);
   }));

   var row1 = [];
   o.rows1 ? row1 = o.rows1 : row1.push(ko.mapping.toJS(new OutcomeRowViewModel()));
   self.rows1 = ko.observableArray($.map(row1, function (obj, i) {
      return new OutcomeRowViewModel(obj);
   }));
};


function ImplementationViewModel(o) {
   var self = this;
   if(!o) o = {};
   self.description = ko.observable(o.description);
};

function EventsRowViewModel(o) {
   var self = this;
   if(!o) o = {};
   self.name = ko.observable(o.name);
   self.description = ko.observable(o.description);
   self.media = ko.observable(o.media);
   self.type = ko.observable(o.type || '');
   self.funding = ko.observable(o.funding).extend({numericString:0}).extend({currency:true});
   self.scheduledDate = ko.observable(o.scheduledDate).extend({simpleDate: false});
   self.grantAnnouncementDate = ko.observable(o.grantAnnouncementDate);
};

function OutcomeRowViewModel(o) {
   var self = this;
   if(!o) o = {};
   self.description = ko.observable(o.description);
   if(!o.assets) o.assets = [];
   self.assets = ko.observableArray(o.assets);
};

function BudgetViewModel(o, period){
   var self = this;
   if(!o) o = {};

   self.overallTotal = ko.observable(0.0);

   var headerArr = [];
   for(i = 0; i < period.length; i++){
      headerArr.push({"data":period[i]});
   }
   self.headers = ko.observableArray(headerArr);

   var row = [];
   o.rows ? row = o.rows : row.push(ko.mapping.toJS(new BudgetRowViewModel({},period)));
   self.rows = ko.observableArray($.map(row, function (obj, i) {
      // Headers don't match with previously stored headers, adjust rows accordingly.
      if(o.headers && period && o.headers.length != period.length) {
         var updatedRow = [];
         for(i = 0; i < period.length; i++) {
            var index = -1;

            for(j = 0; j < o.headers.length; j++) {
               if(period[i] == o.headers[j].data) {
                  index = j;
                  break;
               }
            }
            updatedRow.push(index != -1 ? obj.costs[index] : 0.0)
            index = -1;
         }
         obj.costs = updatedRow;
      }

      return new BudgetRowViewModel(obj,period);
   }));

   self.overallTotal = ko.computed(function (){
      var total = 0.0;
      ko.utils.arrayForEach(this.rows(), function(row) {
         if(row.rowTotal()){
            total += parseFloat(row.rowTotal());
         }
      });
      return total;
   },this).extend({currency:{}});

   var allBudgetTotal = [];
   for(i = 0; i < period.length; i++){
      allBudgetTotal.push(new BudgetTotalViewModel(this.rows, i));
   }
   self.columnTotal = ko.observableArray(allBudgetTotal);
};

function BudgetTotalViewModel (rows, index){
   var self = this;
   self.data =  ko.computed(function (){
      var total = 0.0;
      ko.utils.arrayForEach(rows(), function(row) {
         if(row.costs()[index]){
            total += parseFloat(row.costs()[index].dollar());
         }
      });
      return total;
   },this).extend({currency:{}});
};


function BudgetRowViewModel(o,period) {
   var self = this;
   if(!o) o = {};
   self.shortLabel = ko.observable(o.shortLabel);
   self.description = ko.observable(o.description);

   var arr = [];
   for(i = 0 ; i < period.length; i++)
      arr.push(ko.mapping.toJS(new FloatViewModel()));

   //Incase if timeline is generated.
   if(o.costs && o.costs.length != arr.length) {
      o.costs = arr;
   }
   o.costs ? arr = o.costs : arr;
   self.costs = ko.observableArray($.map(arr, function (obj, i) {
      return new FloatViewModel(obj);
   }));

   self.rowTotal = ko.computed(function (){
      var total = 0.0;
      ko.utils.arrayForEach(this.costs(), function(cost) {
         if(cost.dollar())
            total += parseFloat(cost.dollar());
      });
      return total;
   },this).extend({currency:{}});
};

function FloatViewModel(o){
   var self = this;
   if(!o) o = {};
   self.dollar = ko.observable(o.dollar ? o.dollar : 0.0).extend({numericString:2}).extend({currency:{}});
};

function limitText(field, maxChar){
   $(field).attr('maxlength',maxChar);
}

var EditAnnouncementsViewModel = function(grid, events) {
    var self = this;
    self.modifiedProjects = ko.observableArray([]);
    self.events = events.slice();

    var eventProperties = ['eventName', 'eventDescription', 'funding', 'eventDate', 'grantAnnouncementDate', 'eventType'];
    var projectProperties = ['projectId', 'grantId', 'name'];
    var properties = projectProperties.concat(eventProperties);

    function copyEvent(event) {
        var copy = {};
        for (var i=0; i<eventProperties.length; i++) {
            copy[eventProperties[i]] = event[eventProperties[i]] || '';
        }
        return copy;
    }

    function compareEvents(event1, event2) {

        for (var i=0; i<properties.length; i++) {
            if (!compare(event1[properties[i]], event2[properties[i]])) {
                return false;
            }
        }
        return true;
    }

    /** Compares 2 strings, treating falsely as equal */
    function compare(s1, s2) {
       return (!s1 && !s2) || (s1 == s2);
    }

    function sortEvent(event1, event2) {
        var returnValue = 0;
        var propertyIndex = 0;
        while (returnValue == 0) {
            returnValue = sortByProperty(event1, event2, properties[propertyIndex]);
            propertyIndex++;
        }
        return returnValue;
    }

    function sortByProperty(event1, event2, property) {
        if (event1[property] > event2[property]) { return 1; }
        if (event2[property] > event1[property]) { return -1; }
        return 0;
    }

    function compareProjectEvents(projectEvents1, projectEvents2) {

        if (projectEvents1.length != projectEvents2.length) {
            return false;
        }

        for (var i=0; i<projectEvents1.length; i++) {
            if (!compareEvents(projectEvents1[i], projectEvents2[i])) {
                return false;
            }
        }
        return true;
    }

    self.showBulkUploadOptions = ko.observable(false);
    self.toggleBulkUploadOptions = function() {
        self.showBulkUploadOptions(!self.showBulkUploadOptions());
    };

    self.dirtyFlag = {
        isDirty: ko.computed(function() {
            return self.modifiedProjects().length > 0;
        }),
        reset:function() {
            self.modifiedProjects([]);
        }
    };

    function projectModified(projectId) {
        if (self.modifiedProjects().indexOf(projectId) < 0) {
            self.modifiedProjects.push(projectId);
        }
    }

    function revalidateAll() {
        grid.invalidateAllRows();
        grid.updateRowCount();
        grid.render();
    }

    self.findProjectIdForEvent = function(event) {
        for (var i=0; i<events.length; i++) {
            if (events[i].grantId == event.grantId && events[i].name == event.name) {
                return events[i].projectId;
            }
        }
        return null;
    };

    /**
     * Replaces all of the existing events with the supplied array.
     */
    self.updateEvents = function(newEvents) {
        var i;

        for (i=0; i<newEvents.length; i++) {
            var projectId = self.findProjectIdForEvent(newEvents[i]);
            if (projectId) {
                newEvents[i].projectId = projectId;
            }
            else {
                newEvents[i].grantId = undefined;
                newEvents[i].name = undefined;
            }
        }

        var groupedExistingEvents = {};
        var existingProjectIds = [];
        for (i=0; i<events.length; i++) {
            if (!groupedExistingEvents[events[i].projectId]) {
                groupedExistingEvents[events[i].projectId] = [];
                existingProjectIds.push(events[i].projectId);
            }
            groupedExistingEvents[events[i].projectId].push(events[i]);
        }

        var groupedNewEvents = {};
        var newProjectIds = [];
        for (i=0; i<newEvents.length; i++) {
            if (!groupedNewEvents[newEvents[i].projectId]) {
                groupedNewEvents[newEvents[i].projectId] = [];
                newProjectIds.push(newEvents[i].projectId);
            }
            groupedNewEvents[newEvents[i].projectId].push(newEvents[i]);
        }

        for (i=0; i<existingProjectIds.length; i++) {
            if ((newProjectIds.indexOf(existingProjectIds[i]) < 0) ||
                (!compareProjectEvents(groupedExistingEvents[existingProjectIds[i]], groupedNewEvents[existingProjectIds[i]]))) {
                projectModified(existingProjectIds[i]);
            }
        }

        self.events = newEvents;
        grid.setData(self.events);
        revalidateAll();

        self.validate();
    };

    self.modelAsJSON = function() {
        var projects = [];
        for (var i=0; i<self.modifiedProjects().length; i++) {
            var projectAnnouncements = {projectId:self.modifiedProjects()[i], announcements:[]};
            for (var j=0; j<self.events.length; j++) {
                if (self.events[j].projectId == self.modifiedProjects()[i]) {
                    projectAnnouncements.announcements.push(copyEvent(self.events[j]));
                }

            }
            projects.push(projectAnnouncements);
        }
        return JSON.stringify(projects);
    };

    self.cancel = function() {
        self.cancelAutosave();
        document.location.href = fcConfig.organisationViewUrl;
    };

    self.save = function() {
        Slick.GlobalEditorLock.commitCurrentEdit();
        if (self.validate()) {
            self.saveWithErrorDetection(function() {
                document.location.href = fcConfig.organisationViewUrl;
            });
        }
    };

    self.insertRow = function(index) {
        var event = events[index];
        projectModified(event.projectId);
        self.events.splice(index+1, 0, {projectId:event.projectId, name:event.name, grantId:event.grantId});
        revalidateAll();
    };

    self.deleteRow = function(index) {
        bootbox.confirm("Are you sure you want to delete this announcement?", function(ok) {
            if (ok) {
                var deleted = self.events.splice(index, 1);
                projectModified(deleted[0].projectId);
                revalidateAll();
            }
        });
    };

    self.addRow = function(item, args) {
        self.events.push(item);
        if (item.name) {
            self.projectNameEdited(item, args);
        }
        revalidateAll();
    };

    self.eventEdited = function(event, args) {
        projectModified(event.projectId);
        if (args.cell == 1) {
            self.projectNameEdited(event, args);
            grid.invalidateRow(args.row);
            grid.render();
        }

    };

    self.projectNameEdited = function(event, args) {
        // The project has been changed.
        for (var i=0; i<self.events.length; i++) {
            if (self.events[i].name == event.name) {
                event.projectId = self.events[i].projectId;
                event.grantId = self.events[i].grantId;
                projectModified(event.projectId); // Both the previous and new projects have been modified.
                break;
            }
        }
    };

    self.validate = function() {
        var valid = true;
        var firstErrorPos = 0;
        var columns = grid.getColumns();
        for (var i=0; i<columns.length; i++) {
            if (columns[i].validationRules) {
                var validationFunctions = parseValidationString(columns[i].validationRules);

                for (var project=0; project<self.modifiedProjects().length; project++) {
                    for (var j=0; j<self.events.length; j++) {
                        if (self.events[j].projectId == self.modifiedProjects()[project]) {
                            var field = columns[i]['field'];
                            var value = self.events[j][field];

                            for (var k=0; k<validationFunctions.length; k++) {
                                var result = validationFunctions[k](field, value);
                                if (!result.valid) {
                                    valid = false;
                                    var columnIdx = columnIndex(result.field, grid.getColumns());
                                    var node = grid.getCellNode(j, columnIdx);
                                    if (node) {
                                        var errorPos = $(node).offset().top;
                                        firstErrorPos = Math.min(firstErrorPos, errorPos);
                                        validationSupport.addPrompt($(node), 'event'+j, result.field, result.error);
                                    }
                                }
                            }
                        }
                    }
                }

            }
        }
        if (!valid) {
            window.scroll(0, firstErrorPos);
        }
        return valid;
    };

    // Attach event handlers to the grid
    grid.onAddNewRow.subscribe(function (e, args) {
        var item = args.item;
        self.addRow(item, args);
    });
    grid.onCellChange.subscribe(function(e, args) {
        self.eventEdited(args.item, args);
    });

    grid.onClick.subscribe(function(e) {
        if ($(e.target).hasClass('add-row')) {
            self.insertRow(grid.getCellFromEvent(e).row);
        }
        else if ($(e.target).hasClass('remove-row')) {
            self.deleteRow(grid.getCellFromEvent(e).row);
        }
    });
    grid.onSort.subscribe(function(e, args) {
        var cols = args.sortCols;
        self.events.sort(function (dataRow1, dataRow2) {
            for (var i = 0, l = cols.length; i < l; i++) {
                var field = cols[i].sortCol.field;
                var sign = cols[i].sortAsc ? 1 : -1;
                var value1 = dataRow1[field], value2 = dataRow2[field];
                var result = (value1 == value2 ? 0 : (value1 > value2 ? 1 : -1)) * sign;
                if (result != 0) {
                    return result;
                }
            }
            return 0;
        });
        grid.invalidate();
        grid.render();
    });
    grid.setData(self.events);
};

var Report = function(report) {
    var now = new Date().toISOStringNoMillis();

    var self = this;

    var fromDate = report.fromDate;
    var toDate = report.toDate;
    var dueDate = report.dueDate;
    var name = report.name;
    var description = report.description;

    self.isSubmitted = function() {
        return report.publicationStatus == 'pendingApproval';
    };

    self.isApproved = function() {
        return report.publicationStatus == 'published';
    };


    self.isCurrent = function() {

        return  report.publicationStatus != 'pendingApproval' &&
            report.publicationStatus != 'published' &&
            fromDate < now && toDate >= now;
    };

    self.isDue = function() {
        return report.activityCount > 0 && report.publicationStatus != 'pendingApproval' &&
            report.publicationStatus != 'published' &&
            toDate < now && (!dueDate || dueDate >= now); // Due date is temporarily optional.
    };

    self.isOverdue = function() {
        return report.activityCount > 0 && report.publicationStatus != 'pendingApproval' &&
            report.publicationStatus != 'published' &&
            dueDate && dueDate < now;
    };

    self.status = function() {
        if (self.isOverdue()) {
            return name + ' overdue by '+Math.round(self.overdueDelta())+' day(s)';
        }
        if (self.isDue()) {
            var status = name +  ' due';
            if (dueDate) {
                status += ' on '+convertToSimpleDate(report.dueDate, false);
            }
            return status;
        }
        if (self.isSubmitted()) {
            return name + ' submitted for approval';
        }

        if (self.isCurrent()) {
            return name + ' in progress';
        }
        if (report.activityCount == 0) {
            return name + ' has no activities to report';
        }

        return '';
    };

    self.submissionDelta = function() {
        if (!dueDate) {
            return 0;
        }
        var submitted = moment(report.dateSubmitted);
        var due = moment(report.dueDate);

        return submitted.diff(due, 'days');

    };

    self.overdueDelta = function() {
        if (!dueDate) {
            return 0;
        }
        var due = moment(report.dueDate);

        return moment(now).diff(due, 'days');

    };

    self.getHistory = function() {
        var result = '';
        for (var i=0; i<report.statusChangeHistory.length; i++) {
            result+='<li>'+report.name+' '+report.statusChangeHistory[i].status+' by '+report.statusChangeHistory[i].changedBy+' on '+convertToSimpleDate(report.statusChangeHistory[i].dateChanged, false);
        }

        return result;
    };

}


var ProjectReportsViewModel = function(project) {

    var self = this;

    self.projectId = project.projectId;
    self.organisationId = project.orgIdSvcProvider || project.organisationId;
    self.organisationName = project.serviceProviderName || project.organisationName;
    self.name = project.name;
    self.grantId = project.grantId || '';
    self.associatedProgram = project.associatedProgram;
    self.associatedSubProgram = project.associatedSubProgram;
    self.submittedReportCount = 0;
    self.recommendAsCaseStudy = ko.observable(project.promoteOnHomepage);
    self.activityCount = project.activityCount || 0;

    self.reports = [];
    self.extendedStatus = [];
    var reportingTimeSum = 0;

    var currentReport = null;

    if (project.reports) {
        for (var i=0; i<project.reports.length; i++) {

            var report = new Report(project.reports[i]);
            self.reports.push(report);
            if (!currentReport) {
                currentReport = report;
            }

            // Rule for "current" report is:
            // 1) Any report awaiting action. (Overdue > Submitted).
            // 2) Current stage.

            if (report.isOverdue()) {
                currentReport = report;
            }
            else if (report.isSubmitted() && !currentReport.isOverdue()) {
                currentReport = report;
            }
            else if (report.isDue() && !currentReport.isOverdue() && !currentReport.isSubmitted()) {
                currentReport = report;
            }
            else if (report.isCurrent() && !currentReport.isDue() && !currentReport.isOverdue() && !currentReport.isSubmitted()) {
                currentReport = report;
            }

            if (report.isSubmitted() || report.isApproved()) {
                self.submittedReportCount++;
                reportingTimeSum += report.submissionDelta();
            }


        }

        for (var i=0; i<self.reports.length; i++) {
            var report = self.reports[i];
            if (report.isOverdue() || report.isSubmitted() || report.isDue()) {
                if (report !== currentReport) {
                    self.extendedStatus.push(report.status());
                }
            }
        }
    }


    if (self.submittedReportCount > 0) {
        self.averageReportingTime = reportingTimeSum / self.submittedReportCount;
    }
    else {
        self.averageReportingTime = '';
    }

    self.averageReportingTimeText = function() {
        if (self.submittedReportCount > 0) {
            var deltaDays = Math.round(self.averageReportingTime);
            if (deltaDays < 0) {
                return '<span class="early">'+Math.abs(deltaDays)+' day(s) early</span>';
            }
            else if (deltaDays == 0) {
                return 'on time';
            }
            else {
                return '<span class="late">'+Math.abs(deltaDays)+' day(s) late</span>';
            }
        }
        else {
            return '';
        }
    };

    self.isOverdue = currentReport ? currentReport.isOverdue() : false;

    self.historyVisible = ko.observable(false);

    self.currentStatus = function() {
        if (currentReport) {
            return currentReport.status();
        }

        return 'No current report';
    }();

    self.meriPlanStatus = function() {
        if (project.status == 'Completed') {
            return 'Complete';
        }
        if (project.planStatus === 'approved') {
            return 'Reporting phase';
        }
        if (project.planStatus === 'submitted') {
            return 'MERI plan submitted for approval';
        }
        return 'Planning phase';
    };


    self.getHistory = function() {
        var id = 'reportingHistory-'+project.projectId;
        var history = '<div style="float:right" id="'+id+'"><img src="'+fcConfig.imageLocation+'/ajax-saver.gif"></div>';
        var url = fcConfig.projectReportsUrl+'/'+project.projectId;
        $.ajax({url: url,
            type: 'GET',
            dataType:'html'}).done(function(data) {
                $('#'+id).html(data).slideDown();
            }).fail(function(data) {
                $('#'+id).html('<div float:right">There was an error retrieving the reporting history for this project.</div>');
            }).always(function(data) {
                self.historyVisible(true);
            });


        return history;
    };

    self.extendedStatusVisible = ko.observable(false);

    self.toggleExtendedStatus = function() {
        self.extendedStatusVisible(!self.extendedStatusVisible());
    };

    var toggling = false;
    self.toggleHistory = function(data, e) {

        if (toggling) {
            return;
        }
        toggling = true;

        var tr = $(e.currentTarget).closest('tr');
        var row = tr.closest('table').DataTable().row( tr );
        if ( row.child.isShown() ) {
            // This row is already open - close it
            row.child.hide();
            tr.removeClass('shown');
            self.historyVisible(false);
        }
        else {
            // Open this row
            var data = self.getHistory() || '';

            row.child( data ).show();
            tr.addClass('shown');
        }
        toggling = false;
    };

    self.savingCaseStudy = ko.observable(false);
    self.recommendAsCaseStudy.subscribe(function() {
        var url = fcConfig.projectUpdateUrl + '/' + project.projectId;
        var payload = {promoteOnHomepage:self.recommendAsCaseStudy()};

        self.savingCaseStudy(true);

        // save new status
        $.ajax({
            url: url,
            type: 'POST',
            data: JSON.stringify(payload),
            contentType: 'application/json',

            error: function (data) {
                bootbox.alert('The change was not saved due to a server error or timeout.  Please try again later.', function() {location.reload();});
            },
            complete: function () {
                self.savingCaseStudy(false);
            }
        });
    });

};

var ProjectReportingViewModel = function(projects) {
    var self = this;
    self.projects = [];
    for (var i=0; i<projects.length; i++) {
        self.projects.push(new ProjectReportsViewModel(projects[i].project));
    }
}