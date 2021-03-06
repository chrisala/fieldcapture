<a class="pointer" id="downloadXlsxButton">XLSX</a>
<form id="downloadTabSelection" target="_blank" method="POST" action="${g.createLink(controller: 'search', action: 'downloadAllData')}">

    <input type="hidden" name="view" value="xlsx">
    <g:each in="${params.getList("fq")}" var="selectedFacet">
        <input type="hidden" name="fq" value="${selectedFacet}">
    </g:each>
    <strong>Project Information</strong>
    <ul class="unstyled">
        <g:each in="${['Projects', 'Output Targets', 'Sites', 'Reports', 'Report Summary', 'Documents']}" var="name">
            <li><label class="checkbox"><input type="checkbox" name="tabs" value="${name}" data-validation-engine="validate[minCheckbox[1]]">${name}</label></li>
        </g:each>
    </ul>

    <strong>MERI Plan</strong>
    <ul class="unstyled">
        <g:each in="${['Outcomes', 'Monitoring', 'Project Partnerships', 'Project Implementation', 'Key Evaluation Question', 'Priorities', 'Budget', 'Risks and Threats', 'WHS and Case Study', 'Attachments']}" var="name">
            <li><label class="checkbox"><input type="checkbox" name="tabs" value="${name}" data-validation-engine="validate[minCheckbox[1]]">${name}</label></li>
        </g:each>
    </ul>

    <strong>Activity Data</strong><br/>
    <ul class="unstyled">
        <li><label class="checkbox"><input type="checkbox" name="tabs" value="Activity Summary">Activity Summary</label></li>
    </ul>
    <g:each in="${activityTypes + [name:'Special', list:[[name:'Upload of stage 1 and 2 reporting data']]]}" var="category">
        <strong>${category.name}</strong>
        <ul class="unstyled">
            <g:each in="${category.list}" var="type">
                <li><label class="checkbox"><input type="checkbox" name="tabs" value="${type.name}" data-validation-engine="validate[minCheckbox[1]]">${type.name}</label></li>
            </g:each>

        </ul>
    </g:each>

</form>

<r:script>

$(function() {
   var disabled = false;
   $('#downloadXlsxButton').click(function() {
       if (!disabled) {
           disabled = true;

           $('#downloadXlsxButton').prop('disabled', true);
           var url = "${g.createLink(controller: 'search', action: 'downloadAllData')}";
           bootbox.alert("The download may take several minutes to complete.  Once it is complete, an email will be sent to your registed email address.");
           $.post(url,  $('#downloadTabSelection').serializeArray()).done(function() {
               disabled = false;
               $('#downloadXlsxButton').prop('disabled', false);
           });
       }
   });
});
</r:script>