%{--
  - Copyright (C) 2013 Atlas of Living Australia
  - All Rights Reserved.
  -
  - The contents of this file are subject to the Mozilla Public
  - License Version 1.1 (the "License"); you may not use this file
  - except in compliance with the License. You may obtain a copy of
  - the License at http://www.mozilla.org/MPL/
  -
  - Software distributed under the License is distributed on an "AS
  - IS" basis, WITHOUT WARRANTY OF ANY KIND, either express or
  - implied. See the License for the specific language governing
  - rights and limitations under the License.
  --}%

<%--
  Grails Layout for NRM skin/template, based on http://www.nrm.gov.au/
  User: dos009@csiro.au
  Date: 08/07/13
--%>
<%@ page contentType="text/html;charset=UTF-8" %>
<%@ page import="au.org.ala.fieldcapture.SettingPageType" %>
<!DOCTYPE html>
<!--[if IE 7]><html lang="en" class="ie ie7"><![endif]-->
<!--[if IE 8]><html lang="en" class="ie ie8"><![endif]-->
<!--[if IE 9]><html lang="en" class="ie ie9"><![endif]-->
<!--[if !IE]><!--><html lang="en"><!--<![endif]-->
<head>
    <title><g:layoutTitle /></title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <r:require modules="newSkin, nrmSkin, jquery_cookie"/>
    <r:layoutResources/>
    <link href="https://fonts.googleapis.com/css?family=Oswald:300" rel="stylesheet" type="text/css">
    <link href="https://fonts.googleapis.com/css?family=Source+Sans+Pro:300,400,400italic,600,700" rel="stylesheet" type="text/css">
    <g:layoutHead />
    <g:set var="containerType" scope="request" value="${containerType?:'container'}"/>
</head>
<body class="${pageProperty(name:'body.class')}" id="${pageProperty(name:'body.id')}" onload="${pageProperty(name:'body.onload')}">
<g:set var="introText"><fc:getSettingContent settingType="${SettingPageType.INTRO}"/></g:set>
<g:set var="userLoggedIn"><fc:userIsLoggedIn/></g:set>
<g:if test="${fc.announcementContent()}">
    <div id="announcement">
        ${fc.announcementContent()}
    </div>
</g:if>

<div class="page-header">
    <g:if test="${hubConfig.bannerUrl}">
        <div class="navbar navbar-inverse navbar-static-top" id="header" style="background:url(${hubConfig.bannerUrl}) repeat-x">
    </g:if>
    <g:else>
        <div class="navbar navbar-inverse navbar-static-top" id="header">
    </g:else>
    <g:if test="${fc.currentUserDisplayName()}">
        <div id="logout-warning" class="row-fluid hide">
            <div class="alert alert-error text-center">
                <strong>You have logged out of MERIT from another tab.  Any changes you have made will not be saved to the server until you log back in.</strong>
                <fc:loginInNewWindow>Click here to login again (opens a new window)</fc:loginInNewWindow>
            </div>
        </div>
    </g:if>

        <div class="${containerType}">
            <g:if test="${hubConfig.logoUrl}">
            <div class="nav logo">

                <a href="${createLink(controller:"home")}">
                    %{--<img src="${hubConfig.logoUrl}" alt="${hubConfig.title}" />--}%
                <r:img dir="images" file="ag-Inline_W.png" alt="${hubConfig.title}" />
                </a>

                <g:if test="${hubConfig.title}"><span class="merit">${hubConfig.title}</span></g:if>
            </div>
            </g:if>
            <div class="navbar-form pull-right nav-collapse collapse">
                <g:if test="${fc.currentUserDisplayName()}">
                    <div class="greeting text-right">G'day <fc:currentUserDisplayName/></div>
                </g:if>

                <div class="btn-group pull-right login-logout">
                    <fc:loginLogoutButton logoutUrl="${createLink(controller:'logout', action:'logout')}" cssClass="${loginBtnCss}"/>
                </div>

            </div>

        </div><!--/.container -->


    </div><!--/.navbar -->

    <div class="page-header-menu">
        <div class="${containerType}">
            <div class="nav-collapse collapse pull-right">

                <g:form controller="search" method="GET" class="search merit">
                    <p>
                        <label for="keywords"><span class="hide">Full text search</span><input aria-label="Search MERIT" type="text" name="query" id="keywords" placeholder="Search MERIT" value="${params.query}"></label>
                        <input type="hidden" name="collection" value="agencies">
                        <input type="hidden" name="profile" value="nrm_env">
                        <input type="hidden" name="form" value="simple">
                        <input type="submit" value="search" class="search button">
                    </p>
                </g:form>
            </div>

            <div id="dcNav" class="clearfix ">

                <div class="navbar navbar-inverse">

                    <ul class="nav">
                        <li><a href="${g.createLink(controller: 'home')}" class="active hidden-desktop"><i class="icon-home">&nbsp;</i>&nbsp;Home</a></li>
                    </ul>
                    <a class="btn btn-navbar" data-toggle="collapse" data-target=".nav-collapse">
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                        <span class="icon-bar"></span>
                    </a>
                    <div class="nav-collapse collapse">
                        <ul class="nav">
                            <fc:navbar active="${pageProperty(name: 'page.topLevelNav')}" items="${['home', 'projectExplorer', 'about', 'help', 'contacts']}"/>
                        </ul>
                        <div class="navbar-form pull-right nav-collapse collapse">
                            <span id="buttonBar">
                                <g:render template="/layouts/nrmUserButtons"/>
                                <g:pageProperty name="page.buttonBar"/>
                            </span>
                        </div>
                    </div>
                </div><!-- /.navbar-inner -->
            </div>
        </div>
    </div>
</div>

<div id="content" class="clearfix">
    <g:layoutBody />
</div><!-- /#content -->

<div id="footer">
    <div id="footer-wrapper">
        <div class="${containerType}">
            <fc:footerContent />
        </div>
        <div class="${containerType}">
            <div class="large-space-before">
                <button class="btn btn-mini" id="toggleFluid">toggle fixed/fluid width</button>
                <g:if test="${userLoggedIn && introText}">
                    <button class="btn btn-mini" type="button" data-toggle="modal" data-target="#introPopup">display user intro</button>
                </g:if>
        </div>
    </div>

</div>

<r:script>
    // Prevent console.log() killing IE
    if (typeof console == "undefined") {
        this.console = {log: function() {}};
    }

    $(document).ready(function (e) {

        $.ajaxSetup({ cache: false });

        $("#btnLogout").click(function (e) {
            window.location = "${createLink(controller: 'logout', action:'index')}";
        });

        $(".btnAdministration").click(function (e) {
            window.location = "${createLink(controller: 'admin')}";
        });

        $(".btnProfile").click(function (e) {
            window.location = "${createLink(controller: 'project', action:'mine')}";
        });

        $("#toggleFluid").click(function(el){
            var fluidNo = $('div.container-fluid').length;
            var fixNo = $('div.container').length;
            //console.log("counts", fluidNo, fixNo);
            if (fluidNo > fixNo) {
                $('div.container-fluid').addClass('container').removeClass('container-fluid');
            } else {
                $('div.container').addClass('container-fluid').removeClass('container');
            }
        });

        // Set up a timer that will periodically poll the server to keep the session alive
        var intervalSeconds = 5 * 60;

        setInterval(function() {
            $.ajax("${createLink(controller: 'ajax', action:'keepSessionAlive')}").done(function(data) {});
        }, intervalSeconds * 1000);

    }); // end document ready

</r:script>

<g:if test="${grailsApplication.config.bugherd.integration}">
    <r:script>
        (function (d, t) {
            var bh = d.createElement(t), s = d.getElementsByTagName(t)[0];
            bh.type = 'text/javascript';
            bh.src = '//www.bugherd.com/sidebarv2.js?apikey=cqoc7xdguryihxalktg0mg';
            s.parentNode.insertBefore(bh, s);
        })(document, 'script');
    </r:script>
</g:if>
<!-- current env = ${grails.util.Environment.getCurrent().name} -->
<g:if test="${ grails.util.Environment.getCurrent().name =~ /test|prod/ }">
    <r:script type="text/javascript">

        var _gaq = _gaq || [];
        _gaq.push(['_setAccount', 'UA-4355440-1']);
        _gaq.push(['_setDomainName', 'ala.org.au']);
        _gaq.push(['_trackPageview']);

        (function() {
            var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
            ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
            var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
        })();

    </r:script>
</g:if>

<r:layoutResources/>
</body>
</html>