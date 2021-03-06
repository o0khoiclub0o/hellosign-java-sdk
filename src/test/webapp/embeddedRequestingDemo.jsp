<%@page import="com.hellosign.sdk.HelloSignException"%>
<%@page import="com.hellosign.sdk.HelloSignClient"%>
<%@page import="com.hellosign.sdk.resource.UnclaimedDraft"%>
<%@page import="com.hellosign.sdk.resource.SignatureRequest"%>
<%@page import="org.apache.commons.io.FilenameUtils"%>
<%@page import="org.apache.commons.fileupload.disk.DiskFileItemFactory"%>
<%@page import="org.apache.commons.fileupload.FileItem"%>
<%@page import="java.util.HashMap"%>
<%@page import="java.util.ArrayList"%>
<%@page import="com.hellosign.sdk.resource.support.Signer"%>
<%@page import="java.util.Map"%>
<%@page import="java.io.File"%>
<%@page import="java.util.List"%>
<%@page import="org.apache.commons.fileupload.servlet.ServletFileUpload"%>
<%@page import="java.util.Properties"%>

<%



	// Load authentication properties
	Properties properties = new Properties();
	properties.load(getServletContext().getResourceAsStream("/WEB-INF/web.properties"));
	String apiKey = properties.getProperty("hellosign.api.key");
	String clientId = properties.getProperty("client.id");
	String signUrl = "";
	String errorMessage = null;
    String env = System.getProperty("hellosign.env");
    boolean isLocalDev = "dev".equalsIgnoreCase(env);
    boolean isStaging = "staging".equalsIgnoreCase(env);

	if (ServletFileUpload.isMultipartContent(request)) {

	    List<File> files = new ArrayList<File>();
	    Map<Integer, Signer> signers = new HashMap<Integer, Signer>();
	    String myEmail = null;
	    String myName = null;
	    String subject = null;
	    String message = null;

    	try {
	        // Process the files uploaded by the user
	        List<FileItem> items = new ServletFileUpload(new DiskFileItemFactory()).parseRequest(request);
	        for (FileItem item : items) {
	            if (item.isFormField()) {
	                String fieldName = item.getFieldName();
	                String value = item.getString();
	                System.out.println("item.getFieldName() = " + fieldName);
	                System.out.println("item.getString() = " + value);
	                if (value == null || value.equals("") || fieldName == null || fieldName.equals("")) {
	                    continue;
	                }
	                if (fieldName.startsWith("signer")) {
	                    int i = Integer.valueOf(fieldName.substring(6, 7)) - 1;
	                    Signer s;
	                    if (!signers.containsKey(i)) {
	                        s = new Signer();
	                        signers.put(i, s);
	                    } else {
	                        s = signers.get(i);
	                    }
	                    String type = fieldName.substring(8, fieldName.length());
	                    if ("name".equals(type)) {
	                        s.setNameOrRole(value);
	                    } else if ("email".equals(type)) {
	                        s.setEmail(value);
	                    }
	                } else if ("yourName".equals(fieldName)) {
	                    myName = value;
	                } else if ("yourEmail".equals(fieldName)) {
	                    myEmail = value;
	                } else if ("subject".equals(fieldName)) {
	                    subject = value;
	                } else if ("message".equals(fieldName)) {
	                    message = value;
	                }
	            } else {
	                String filename = FilenameUtils.getName(item.getName());
	                if (filename == null || filename.equals("")) {
	                    continue;
	                }
	                String prefix = filename.substring(0, filename.indexOf("."));
	                String suffix = filename.substring(filename.indexOf("."), filename.length());
	                File outfile = File.createTempFile(prefix, suffix);
	                item.write(outfile);
	                System.out.println("Saved upload to: " + outfile.getAbsolutePath());
	                files.add(outfile);
	            }
	        }
	    } catch (Exception e) {
	    	errorMessage = e.getMessage();
	        e.printStackTrace();
	    }
	    if (files.size() > 0) {
	        try {
	        	// Create a signature request
	            SignatureRequest sigReq = new SignatureRequest();
	            sigReq.setTestMode(true);
	            if (subject != null) {
	            	sigReq.setSubject(subject);
	            }
	            if (message != null) {
	            	sigReq.setMessage(message);
	            }
	            if (signers.size() > 0) {
		            for (Integer key : signers.keySet()) {
		                Signer s = signers.get(key);
		                sigReq.addSigner(s.getEmail(), s.getNameOrRole());
		            }
		        }
	            if (myEmail != null) {
	            	sigReq.setRequesterEmail(myEmail);
	            }
	            for (File file : files) {
	                sigReq.addFile(file);
	            }

	            // Create an unclaimed draft from the request
				UnclaimedDraft draft = new UnclaimedDraft(sigReq);
				draft.setIsForEmbeddedSigning(true);
	            draft.setClientId(clientId);

	            // Send it to HelloSign
	            HelloSignClient client = new HelloSignClient(apiKey);
	            UnclaimedDraft responseDraft = client.createUnclaimedDraft(draft);

	         	// Retrieve the embedded signing URL from the response
	            signUrl = responseDraft.getClaimUrl();

	        } catch (HelloSignException ex) {
	        	errorMessage = ex.getMessage();
	            ex.printStackTrace();
	        }
	    }
	}
%>
<html>
    <head>
        <title>Embedded Signature Request Demo | HelloSign</title>
        <script type="text/javascript" src="/js/jquery.js"></script>
<% if (isLocalDev) { %>
        <script type="text/javascript" src="//www.my.hellosign.com/js/embedded.js"></script>
<% } else if (isStaging) { %>
        <script type="text/javascript" src="//staging.hellosign.com/js/embedded.js"></script>
<% } else { %>
        <script type="text/javascript" src="//s3.amazonaws.com/cdn.hellofax.com/js/embedded.js"></script>
<% } %>
        <link rel="stylesheet" type="text/css" media="screen" href="/css/prettify.css" />
        <link rel="stylesheet" type="text/css" media="screen" href="/css/main.css" />
        <link rel="stylesheet" type="text/css" media="screen" href="/css/main-loggedOut.css" />
        <link rel="stylesheet" type="text/css" media="screen" href="/css/demos.css" />
        <script type="text/javascript" src="/js/init.js"></script>
        <script type="text/javascript" src="/js/prettify.js"></script>
        <link rel="stylesheet" type="text/css" media="screen" href="/css/hs/main.css" />
        <script type="text/javascript" src="/js/main.js" ></script>
        <link rel="shortcut icon" href="/favicon.ico" />
        <link rel="apple-touch-icon" href="/apple-touch-icon-precomposed.png" />
        <style>
            html { background-color: white !important; }
            pre { font-family: Monaco; font-size: 13px; margin-left: 15px; margin-top: 5px; }
            input#startButton { padding: 10px 20px; height: 40px; font-size: 16px; }
            input[type='file'] { padding: 5px; border: 1px solid #EEE; clear:both; }
            label { display: inline; margin-left: 4px;}
            button#addFile { margin-left: 10px;}
            button#addSigner { margin-left: 10px;}
            div#files { margin-bottom: 5px;}
            div#signers { margin-bottom:5px;}
            div#fileContainer { width: 400px;}
            div#demoForm {border: 1px solid gray; padding: 20px;}
            div#message { margin: 10px; color: red; }
        </style>
        <script type='text/javascript'>
            var fileCount = 1;
            var signerCount = 1;
            function removeFile(fileNumber) {
                var el = $("#fileDiv_" + fileNumber);
                if (el) {
                    el.remove();
                }
                return false;
            }
            function removeSigner(signerNumber) {
                var el = $("#fileDiv_" + fileNumber);
                if (el) {
                    el.remove();
                }
                return false;
            }
            $(document).ready(function(){
                initEmbeddedDemo();
                $("#startButton").hide();
                $("#addFile").click(function(e) {
                    fileCount++;
                    $("#files").append('<div id="fileDiv_' + fileCount + '"><input id="file_' + fileCount + '" type="file" name="file_' + fileCount + '" />&nbsp;<button onclick="removeFile(' + fileCount + '); return false;">X</button></div>');
                    return false;
                });
                $("#addSigner").click(function(e) {
                    signerCount++;
                    $("#signers").append('<div id="signerDiv_' + signerCount + '"><br /><input type="text" name="signer' + signerCount + '_name" placeholder="Signer name" /> <input type="text" name="signer' + signerCount + '_email" placeholder="Signer email" />&nbsp;<button onclick="removeSigner(' + signerCount + '); return false;">X</button></div>');
                    return false;
                });
                $("#file_1").change(function(e) {
                	$("#startButton").show();
                });
<% if (signUrl != "") { %>
                // Initialize HelloSign with the client ID
                HelloSign.init("<%= clientId %>");

                // Open the iFrame dialog for embedded signing
                HelloSign.open({
                    url: "<%= signUrl %>",
                    debug: true,
                    allowCancel: true,
                    messageListener: function(eventData) {
                    	console.log("Event received:");
                        console.log(eventData);
                        var msg;
                        if (eventData.event == HelloSign.EVENT_SENT) {
                        	msg = "Request Sent!";
                        } else if (eventData.event == HelloSign.EVENT_SIGNED) {
                        	msg = "Request Signed!";
                        } else {
                        	msg = eventData.event;
                        }
                        $("#demoForm").html(msg + "<br /><a href=\"/embeddedRequestingDemo.jsp\">Try it again</a>");
                    }
                });
<% } %>
            });
        </script>
    </head>
    <body class="api documentation logged-out " id="hs">
        <div id="wrap">
            <div id="container">
                 <div id="header">
                     <a href="https://www.hellosign.com"><span id="logo"></span></a>
                     <a href="https://www.hellosign.com/api/gettingStarted" class="nav">Getting Started</a>
                     <a href="https://www.hellosign.com/api/embedded" class="nav selected">Embedded</a>
                     <a href="https://www.hellosign.com/api/reference" class="nav">API Reference</a>
                     <a href="https://www.hellosign.com/api/libraries" class="nav">Libraries</a>
                     <a href="https://www.hellosign.com/api/pricing" class="nav">Pricing</a>
                     <a id="signinButton" class="signin blue-sub" href="https://www.hellosign.com/account/logIn">Sign in</a>
                 </div>
                <div id="main-content">
                	<div class="sub-nav"><a href="/">Index</a> <span class="rsaquo">&rsaquo;</span> Embedded Request Demo</div>
                    <h2 class="page-title default headline">Embedded Request Demo</h2>
                    <div class="embeddedSigning bs_container">
                        <p class="intro">
                            Request signatures for documents directly from your website with HelloSign's embedded request capability. Follow the steps below to add this feature to your Java-based web application.
                        </p>
                        <br />
                        <div class="row">
                            <div class="span12">
                                <h2>Before You Begin</h2>
                                <ul>
                                    <li><b>1.</b>&nbsp;Obtain an API key.<br />Sign up for an API plan <a href="https://www.hellosign.com/api/pricing">here</a>. Adding embedded signing to your website requires a Silver or Gold API plan. However, you can test the functionality for free by creating signature requests in test mode.</li>
                                    <li><b>2.</b>&nbsp;Obtain a Client ID.<br />Sign up for a Client ID for your application <a href="https://www.hellosign.com/oauth/createAppForm">here</a>.</li>
                                    <li><b>3.</b>&nbsp;Set the API key and Client ID in the properties file:<br /><pre class="code-render prettyprint">hellosign-java-sdk/src/main/webapp/WEB-INF/web.properties</pre></li>
                                </ul>
                                <br />
                                <form action="/embeddedRequestingDemo.jsp" method="post" enctype="multipart/form-data">
                                    <h2>Try It Out</h2>
<% if (errorMessage != null) { %>
                                    <div id="message"><%= errorMessage %></div>
<% } %>
                                    <div id="demoForm">
                                        <h3>What needs to be signed?</h3>
                                        <div id="fileContainer">
                                            <div id="files" >
                                                <input id="file_1" type="file" name="file_1" />
                                            </div>
                                            <button id="addFile">Add File</button>
                                        </div>
                                        <br />
                                        <h3>Who are you?</h3>
                                        <input type="text" name="yourName" placeholder="Your name" /> <input type="text" name="yourEmail" placeholder="Your email" />
                                        <br />
                                        <br />
                                        <p><em>The information below is optional. If you leave these fields blank, HelloSign will walk you through the information it needs.</em></p>
                                        <br />
                                        <h3>Who needs to sign it?</h3>
                                        <div id="signerContainer">
                                            <div id="signers">
                                                <input type="text" name="signer1_name" placeholder="Signer name" /> <input type="text" name="signer1_email" placeholder="Signer email" />
                                            </div>
                                            <button id="addSigner">Add Signer</button>
                                        </div>
                                        <br />
                                        <h3>Anything else?</h3>
                                        <input type="text" name="subject" placeholder="Subject (optional)" /><br /><br />
                                        <input type="text" name="message" placeholder="Message (optional)" style="width:400px; height: 100px;" />
                                    </div>
                                    <br />
                                    <input class="btn blue-sub" id="startButton" type="submit" value="Upload and Launch Demo" />
                                </form>
                                <br />
                                <br />
                                <h2>Creating an Embedded Signature Request</h2>
                                <p>The steps below demonstrate how to embedded a signature request capability into a JSP-based web page, but the steps are similar for other JEE-based applications. See the server-side source of this file for the code used in this example.</p><br />
                                <ul>
                                    <li><b>1.</b>&nbsp;Provide a way for your users to specify the parameters of their request. Specifically, they should be able to specify the following:
                                        <ol><li>File(s) for the request</li>
                                            <li>The name(s) and email address(es) of their signer(s)</li>
                                            <li>Their name and email address</li>
                                            <li>Messaging parameters for the request (subject and message)</li>
                                        </ol>
                                        This JSP page provides entry capability for these items and also processes them when the user clicks the submit button. When the necessary information has been submitted, it will proceed to create the embedded request.</li>
                                    <li><b>2.</b>&nbsp;<b>Server-side</b>: Import the packages for hellosign-java-sdk and its dependencies.<br /><pre class="code-render prettyprint">&lt;%@ page import="com.hellosign.sdk.*,com.hellosign.sdk.resource.*,com.hellosign.sdk.resource.support.*,java.io.*,java.util.*,org.apache.commons.fileupload.*,org.apache.commons.fileupload.servlet.*,org.apache.commons.fileupload.disk.*,org.apache.commons.io.*" %&gt;</pre></li>
                                    <li><b>3.</b>&nbsp;<b>Server-side</b>: Obtain the information provided by the user in Step 1 and create an Unclaimed Draft.<br />
<pre class="code-render prettyprint">
    // Create a signature request
    SignatureRequest sigReq = new SignatureRequest();
    sigReq.setTestMode(true);
    for (File file : files) {
        sigReq.addFile(file);
    }

    // Create an unclaimed draft from the request
    UnclaimedDraft draft = new UnclaimedDraft(sigReq);
    draft.setIsForEmbeddedSigning(true);
    draft.setClientId(clientId);
</pre>
                                    </li>
                                    <li><b>4.</b>&nbsp;<b>Server-side</b>: Retrieve the URL for the unclaimed draft.<br />
<pre class="code-render prettyprint">
    HelloSignClient client = new HelloSignClient(apiKey);
    UnclaimedDraft responseDraft = client.createUnclaimedDraft(draft);
    signUrl = responseDraft.getClaimUrl();
</pre>
                                    </li>
                                    <li><b>5.</b>&nbsp;<b>Client-side</b>: Include "embedded.js".<br /><pre class="code-render prettyprint">&lt;script type="text/javascript" src="//s3.amazonaws.com/cdn.hellofax.com/js/embedded.js"&gt;&lt;/script&gt;</pre></li>
                                    <li><b>6.</b>&nbsp;<b>Client-side</b>: Use the server-generated client ID and URL from Step 4 to initialize the HelloSign JavaScript components. In JSP, this can be done like so:<br />
<pre class="code-render prettyprint">&lt;script type="text/javascript"&gt;
    function openSigningDialog() {
        HelloSign.init("&lt;%= clientId %&gt;");
        HelloSign.open({
            url: "&lt;%= embeddedResponse.getSignUrl() %&gt;"
        });
    }
&lt;/script&gt;</pre>
                                </ul>
                                <br />
                                <br />
                                <br />
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        </div>
        <div id="footer" class="border-box">
            <div class="footer_container">
                <div class="inner border-box">
                    <div id="footer_links" class="clearfix">
                        <div class="col left">
                            <span><a id="footer_contact" href="https://www.hellosign.com/info/contact">Contact</a></span> <span><a id="footer_about_us" href="https://www.hellosign.com/info/aboutUs">About Us</a></span> <span><a id="footer_pricing" href="https://www.hellosign.com/info/pricing">Pricing</a></span> <span><a id="footer_benefits" href="https://www.hellosign.com/info/benefits">Benefits</a></span>
                        </div>
                        <div class="col left">
                            <span><a target="_blank" id="footer_faq" href="http://faq.hellofax.com">FAQ</a></span> <span><a target="_blank" id="footer_hs" href="https://www.my.hellosign.com/webapp_dev.php/">HelloSign</a></span> <span><a id="footer_security" href="https://www.hellosign.com/info/security">Security</a></span> <span><a target="_blank" id="footer_blog" href="http://blog.hellofax.com">Blog</a></span>
                        </div>
                        <div class="col left">
                            <span><a id="footer_jobs" href="https://www.hellosign.com/info/jobs">Jobs</a></span> <span><a id="footer_legal" href="https://www.hellosign.com/info/legal">Legal</a></span> <span><a id="footer_privacy" href="https://www.hellosign.com/info/privacyPolicy">Privacy</a></span> <span><a id="footer_tos" href="https://www.hellosign.com/info/tos">Terms</a></span>
                        </div>
                        <p class="legal">
                            &copy; <strong>HelloFax, Inc.</strong>, 2014. All rights reserved.
                        </p>
                        <div class="clearfix"></div>
                    </div><br>
                </div>
            </div>
        </div>
    </body>
</html>