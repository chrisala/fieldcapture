<!--  Case manager actions -->
<div class="row-fluid space-after">	
	<div class="span6 required">
			<div data-bind="if: userIsCaseManager()">
				<div data-bind="if: planStatus() == 'approved'">
					<div class="form-actions">
							<b>Case manager actions:</b>
				            <button type="button" data-bind="click: modifyPlan"  id="modify-plan" class="btn btn-info">Modify project</button>
				            <br/><br/>		
							<ul>
								<li>"Modify project" will allow project admin's to edit project information. </li>
								<li>Modifying the project will change the state of the project to "Not approved".</li>
							</ul>
					</div>
				</div>	
				<div data-bind="if: planStatus() == 'submitted'">
					<div class="form-actions" >
							<b>Case manager actions:</b>
						    <span class="btn-group">
		      					<button type="button" data-bind="click:approvePlan" class="btn btn-success"><i class="icon-ok icon-white"></i> Approve</button>
		      					<button type="button" data-bind="click:rejectPlan" class="btn btn-danger"><i class="icon-remove icon-white"></i> Reject</button>
			  				</span>
					</div>
				</div>
			</div>
			
	</div>
</div>	
<div class="row-fluid">
    <div class="control-group">
        <div style="float: left;" class="controls">
           <b>From: </b><span data-bind="text: plannedStartDate.formattedDate"></span>  <b>To: </b> <span data-bind="text: plannedEndDate.formattedDate"></span>
        </div>
		<div style="float: right;" data-bind="if: planStatus() == 'approved'">
        	<span class="badge badge-success" style="font-size: 13px;">This plan has been approved</span>
        	<span data-bind="if:detailsLastUpdated"> <br/>Last update date : <span data-bind="text:detailsLastUpdated.formattedDate"></span></span>
        </div>
        <div style="float: right;" data-bind="if: planStatus() == '' || planStatus() == 'not approved' ">
        	<span class="badge badge-warning" style="font-size: 13px;">This plan is not yet approved</span>
        	<span data-bind="if:detailsLastUpdated"><br/>Last update date :  <span data-bind="text:detailsLastUpdated.formattedDate"></span></span>
        </div>
        <div style="float: right;" data-bind="if: planStatus() == 'submitted'">
        	<span class="badge badge-info" style="font-size: 13px;">This plan has been submitted for approval</span>
        	<span data-bind="if:detailsLastUpdated"><br/>Last update date :  <span data-bind="text:detailsLastUpdated.formattedDate"></span></span>
        </div>
       
    </div>
</div>

<div class="row-fluid space-after">
	    <div class="required">
	        <div class="well well-small">
	 			<label><b>Project objectives</b></label> 	 
	 			<table style="width: 100%;">
			        <thead>
			            <tr>
			                <th>Objectives<span style="color: red;"><b>*</b></span><fc:iconHelp title="Objectives"></fc:iconHelp></th>
			                <th>Natural assets protected <span style="color: red;"><b>*</b></span><fc:iconHelp title="Natural assets protected"></fc:iconHelp></th>
			            </tr>
			        </thead>
			        <tbody>
			        	<tr>
				        	<td width="70%"><textarea style="width: 99%;" data-bind="value: details.objectives.description, disable: isProjectDetailsLocked()" data-validation-engine="validate[required]" rows="5" ></textarea></td>
				        	<td width="30%"><select style="width: 99%;float:right;" class="input-xlarge" 
				        		data-bind="options: protectedNaturalAssests, selectedOptions: details.objectives.assets, disable: isProjectDetailsLocked()" size="5" multiple="true" data-validation-engine="validate[required]"></select></td>
			        	</tr>
			        </tbody>
	 			</table>
	 			
			    <table style="width: 100%;">
			        <thead>
			            <tr>
			            	<th></th>
			                <th>Monitoring indicator<span style="color: red;"><b>*</b></span><fc:iconHelp title="Monitoring indicator"></fc:iconHelp></th>
			                <th>Monitoring approach <fc:iconHelp title="Monitoring approach"></fc:iconHelp></th>
			                <th></th>
			            </tr>
			        </thead>
			        <tbody data-bind="foreach : details.objectives.rows">
			                <tr>
			                	<td width="2%"> <span data-bind="text:$index()+1"></span></td>
			                    <td width="30%"> <input style="width: 97%;" type="text"  class="input-xlarge"  data-bind="value: data1, disable: $parent.isProjectDetailsLocked()" data-validation-engine="validate[required]"> </td>
			                    <td width="64%"> <textarea style="width: 97%;" data-bind="value: data2, disable: $parent.isProjectDetailsLocked()" rows="5" ></textarea> </td>
			                    <td width="4%">
                        			<span data-bind="if: $index() && !$parent.isProjectDetailsLocked()"><i class="icon-remove" data-bind="click: $parent.removeObjectives"></i></span>
			                    </td>
			                </tr>
			        </tbody>
	                <tfoot>
          				<tr>
          					<td></td>
          					<td colspan="0" style="text-align:left;">
                  			<button type="button" class="btn btn-small" data-bind="disable:isProjectDetailsLocked(), click: addObjectives">
                  			<i class="icon-plus"></i> Add a row</button>
                  			</td>
                  		</tr>
  					</tfoot>
			    </table>
	        </div>
	    </div>
</div>


<div class="row-fluid space-after">
	<div class="required">
	        <div id="national-priorities" class="well well-small">
	 			<label><b>National and regional priorities</b></label> 	 
		        <p>Explain how the project aligns with all applicable national and regional priorities, plans and strategies.</p>	        
			    <table style="width: 100%;">
			        <thead>
			            <tr>
			            	<th></th>
			                <th>Document name<span style="color: red;"><b>*</b></span> <fc:iconHelp title="Document name">Enter the name of the plan/strategy document which this project is contributing to achieving outcomes for.</fc:iconHelp></th>
			                <th>Relevant section <fc:iconHelp title="Relevant section">Enter the section/sub-section, clause or reference number of the relevant strategic objective section in the document, which this project is addressing.</fc:iconHelp></th>
			                <th>Explanation of strategic alignment <fc:iconHelp title="Explanation of strategic alignment">Explain how the project is addressing this objective in the plan/strategy document.</fc:iconHelp></th>
							<th></th>			                
			            </tr>
			        </thead>
			        <tbody data-bind="foreach : details.priorities.rows">
			                <tr>
			                	<td width="2%"> <span data-bind="text:$index()+1"></span></td>
			                    <td width="30%"> <input style="width: 97%;" type="text"  class="input-xlarge"  data-bind="value: data1, disable: $parent.isProjectDetailsLocked()" data-validation-engine="validate[required]"> </td>
			                    <td width="32%"> <textarea style="width: 97%;" class="input-xlarge" data-bind="value: data2, disable: $parent.isProjectDetailsLocked()"  rows="5"></textarea></td>
			                    <td width="32%"> <textarea style="width: 97%;" class="input-xlarge" data-bind="value: data3, disable: $parent.isProjectDetailsLocked()"  rows="5"></textarea></td>
			                    <td width="4%"> 
                        			<span data-bind="if: $index() && !$parent.isProjectDetailsLocked()"><i class="icon-remove" data-bind="click: $parent.removeNationalAndRegionalPriorities"></i></span>
			                    </td>		                    
			                </tr>
					 </tbody>
 					<tfoot>
           				<tr>
           					<td></td>
           					<td colspan="0" style="text-align:left;">
                   			<button type="button" class="btn btn-small" data-bind="disable: isProjectDetailsLocked(), click: addNationalAndRegionalPriorities">
                   			<i class="icon-plus"></i> Add a row</button></td>
                   		</tr>
					</tfoot>
			    </table>
	        </div>
	    </div>
</div>


<div class="row-fluid space-after">
		    <div class="required">
		        <div id="project-implementation" class="well well-small">
		 			<label><b>Project implementation / delivery mechanism</b></label> 
		 			<p>Explain how the project will be implemented, including methods, approaches, collaborations, etc. <fc:iconHelp title="Project implementation / delivery mechanism"></fc:iconHelp></p>	        
					<textarea style="width: 98%;" maxlength="500" 
						data-bind="value:details.implementation.description, disable: isProjectDetailsLocked()" 
						class="input-xlarge" id="implementation" rows="10" data-validation-engine="validate[required]"></textarea>
		        </div>
		    </div>
</div>

<div class="row-fluid space-after">
        <div id="project-partnership" class="well well-small">
 			<label><b>Project partnerships</b></label> 
 			<p>Provide details on all project partners and the nature and scope of their participation in the project.</p>	        
			<table style="width: 100%;">
			        <thead>
			            <tr>
			            	<th></th>
			                <th>Partner name<span style="color: red;"><b>*</b></span>
			                <fc:iconHelp title="Partner name"></fc:iconHelp></th>
			                <th>Nature of partnership<fc:iconHelp title="Nature of partnership"></fc:iconHelp></th>
			                <th>Type of organisation<fc:iconHelp title="Type of organisation"></fc:iconHelp></th>
							<th></th>			                
			            </tr>
			        </thead>
			        <tbody data-bind="foreach : details.partnership.rows">
			                <tr>
			                	<td width="2%"> <span data-bind="text:$index()+1"></span></td>
			                    <td width="20%"> <input style="width: 97%;" type="text"  class="input-xlarge"  data-bind="value: data1, disable: $parent.isProjectDetailsLocked()" data-validation-engine="validate[required]"> </td>
			                    <td width="54%"><textarea style="width: 97%;" class="input-xlarge" data-bind="value: data2, disable: $parent.isProjectDetailsLocked()"  rows="5"></textarea></td>
			                    <td width="20%"><select style="width: 97%;" class="input-xlarge" data-bind="options: $parent.organisations, value:data3,optionsCaption: 'Please select',disable: $parent.isProjectDetailsLocked()"></select></td>
			                    <td width="4%"> 
                        			<span data-bind="if: $index() && !$parent.isProjectDetailsLocked()" ><i class="icon-remove" data-bind="click: $parent.removePartnership"></i></span>
			                    </td>		                    
			                </tr>
					 </tbody>
 					<tfoot>
             				<tr>
             					<td></td>
             					<td colspan="0" style="text-align:left;">
                     			<button type="button" class="btn btn-small"  data-bind="disable: isProjectDetailsLocked(), click: addPartnership">
                     			<i class="icon-plus"></i> Add a row</button></td>
                     		</tr>
					</tfoot>
			    </table>
        </div>
</div>

<div class="row-fluid space-after">
	<div class="required">
	        <div id="keq" class="well well-small">
	 			<label><b>Key evaluation question</b></label> 	 
			    <table style="width: 100%;">
			        <thead>
			            <tr>
			            	<th></th>
			                <th>Project Key evaluation question (KEQ)<span style="color: red;"><b>*</b></span>
			                <fc:iconHelp title="Project Key evaluation question (KEQ)"></fc:iconHelp></th>
			                <th>How will KEQ be monitored 
			                <fc:iconHelp title="How will KEQ be monitored"></fc:iconHelp></th>
							<th></th>			                
			            </tr>
			        </thead>
			        <tbody data-bind="foreach : details.keq.rows">
			                <tr>
			                	<td width="2%"> <span data-bind="text:$index()+1"></span></td>
			                    <td width="32%"> 
		                    		<textarea style="width: 97%;" rows="2"  class="input-xlarge"  data-bind="value: data1, disable: $parent.isProjectDetailsLocked()" data-validation-engine="validate[required]"> 
		                    		</textarea>
			                    </td>
			                    <td width="52%"><textarea style="width: 97%;" class="input-xlarge" data-bind="value: data2, disable: $parent.isProjectDetailsLocked()"  rows="5"></textarea></td>
			                    <td width="4%"> 
                        			<span data-bind="if: $index() && !$parent.isProjectDetailsLocked()" ><i class="icon-remove" data-bind="click: $parent.removeKEQ"></i></span>
			                    </td>		                    
			                </tr>
					 </tbody>
 					<tfoot>
           				<tr>
           					<td></td>
           					<td colspan="0" style="text-align:left;">
                   			<button type="button" class="btn btn-small" data-bind="disable: isProjectDetailsLocked(), click: addKEQ">
                   			<i class="icon-plus"></i> Add a row</button></td>
                   		</tr>
					</tfoot>
			    </table>
	        </div>
	    </div>
</div>

<div class="row-fluid space-after">
	<div class="required">
	        <div class="well well-small">
	 			<div>1. Are you aware of, and compliment with, your workplace health and safety legislation and obligations.<span style="color: red;"><b>*</b></span> 
	 				<select style="width: 10%;" data-bind="options: obligationOptions, optionsCaption: 'Please select', value:details.obligations, disable: isProjectDetailsLocked()" data-validation-engine="validate[required]"> </select>
	 			</div>	
			    <div>
			    	 2. Please briefly describe key workplace health and safety risks that you have considered as part of your project planning processes and how you are managing / mitigating these identified risks. <span style="color: red;"><b>*</b></span><br/>
			    	<textarea style="width: 99%;" data-bind="value: details.workplace, disable: isProjectDetailsLocked()" data-validation-engine="validate[required]" rows="4" ></textarea>
		    	</div>
	        </div>
	    </div>
</div>

<!-- Budget table -->
<div class="row-fluid space-after">
	<div class="required">
	        <div class="well well-small">
	 			<label><b>Budget table</b></label>
	 			Budget summary <span style="color: red;"><b>*</b></span> <fc:iconHelp title="Budget summary"></fc:iconHelp>
	 			<textarea style="width: 99%;" data-bind="value: details.budget.description, disable: isProjectDetailsLocked()" data-validation-engine="validate[required]" rows="4" ></textarea> 	 
			    <table style="width: 100%;">
			        <thead>
			            <tr>
			            	<th width="2%"></th>
			                <th width="10%">Investment/Priority Area<span style="color: red;"><b>*</b></span> <fc:iconHelp title="Investment/Priority Area"></fc:iconHelp></th>
			                <th width="10%">Description <fc:iconHelp title="Description"></fc:iconHelp></th>
			                <!-- ko foreach: details.budget.headers -->
			                	<th style="text-align: center;" width="10%" ><div style="text-align: center;" data-bind="text:data"></div>$<span style="color: red;"><b>*</b></span></th>
			                <!-- /ko -->
							<th  style="text-align: center;" width="10%">Total</th>
							<th width="4%"></th>
			            </tr>
			        </thead>
			        <tbody data-bind="foreach : details.budget.rows">
			                <tr>
			                	<td><span data-bind="text:$index()+1"></span></td>
			                    <td><select style="width: 97%;" data-bind="options: $parent.projectThemes, optionsCaption: 'Please select', value:shortLabel, disable: $parent.isProjectDetailsLocked()" data-validation-engine="validate[required]"> </select></td>
			                   	<td><textarea style="width: 95%;" data-bind="value: description, disable: $parent.isProjectDetailsLocked()" rows="2"></textarea></td>
							
								<!-- ko foreach: costs -->
		                    		<td><div style="text-align: center;">
		                    			<input data-validation-engine="validate[required]" style="text-align: center; width: 80%;" class="input-xlarge" data-bind="value: dollar, numeric: $root.number, disable: $root.isProjectDetailsLocked()" />
		                    			</div>
		                    		</td>
		                    	<!-- /ko -->
			                    
			                    <td style="text-align: center;" ><span style="text-align: center;" data-bind="text: rowTotal.formattedCurrency, disable: $parent.isProjectDetailsLocked()"></span></td>
			                    <td> 
                        			<span data-bind="if: $index() && !$parent.isProjectDetailsLocked()" ><i class="icon-remove" data-bind="click: $parent.removeBudget"></i></span>
			                  	</td>
			                </tr>
					 </tbody>
 					<tfoot>
           				<tr>
           					<td></td>
           					<td colspan="0" style="text-align:left;">
                   			<button type="button" class="btn btn-small" data-bind="disable: isProjectDetailsLocked(), click: addBudget">
                   			<i class="icon-plus"></i> Add a row</button></td>
							<td style="text-align: right;" ><b>Total </b></td>
							<!-- ko foreach: details.budget.columnTotal -->
								<td style="text-align: center;" width="10%"><span data-bind="text:data.formattedCurrency"></span></td>
							<!-- /ko -->
							<td style="text-align: center;"><b><span data-bind="text:details.budget.overallTotal.formattedCurrency"></span></b></td>
                   		</tr>
					</tfoot>
			    </table>
	        </div>
	    </div>
</div>


<div id="save-details-result-placeholder"></div>

<div class="row-fluid space-after">
	<div class="span6 required">
		<div class="form-actions">
	            <button type="button" data-bind="click: saveProjectDetails, disable: isProjectDetailsLocked()" id="project-details-save" class="btn btn-primary">Save changes</button>
	            <button type="button" id="details-cancel" class="btn">Cancel</button>
				<!--  Admin - submit to approval. -->
				<div data-bind="if: userIsAdmin()">
					<div data-bind="if: planStatus() == 'not approved' || planStatus() == ''">
						<hr/>
						<b>Admin actions:</b>
						<ul>
							<li>Build your project by adding project details, activities and project targets information.</li>
							<li>Save your changes before submitting for approval: <button type="button" data-bind="click: submitChanges, enable: isProjectDetailsSaved()"  id="modify-plan" class="btn btn-info">Submit for approval</button></li>
						</ul>
					</div>
					<div data-bind="if: planStatus() == 'submitted' || planStatus() == 'approved'">
						<hr/>
						<b>Admin:</b>
						<ul>
							<li>Your project is locked until it is approved by your case manager.</li> 
							<li>Once your plan is approved you can start editing project information.</li>
						</ul>
					</div>	
				</div>
		</div>
		
	</div>
</div>