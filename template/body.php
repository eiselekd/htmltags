<?
require("Sajax.php");

function show_now() {
	//return server date
	return date("l dS of F Y h:i:s A");
}

//starting SAJAX stuff
$sajax_request_type = "GET";
sajax_init();
sajax_export("show_now");
sajax_handle_client_request();
?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en" dir="ltr">
  <head>
    <style type="text/css">
      a.def {
      color: #aaaaaa;
      }
      a.close {
      color: #aaaaaa;
      }
      pre {
      line-height: 20px;
      }
      span.macrou {
      background-color:  #fbfbfb;
      margin: 0px;
      padding-top: 2px;
      padding-bottom: 2px;
      border: 1px solid grey
      }
      span.macroe {
      background-color: #f0f0f0;
      margin: 0px;
      border: 1px solid grey;
      }
      div.finc {
      background-color: #f0f0f0;
      /*margin-left:8px*/
      }
    </style>
    
    <script language="JavaScript1.2" type="text/javascript">
        <?
        sajax_show_javascript();
        ?>
      
var closednodes = new Array();

function importXML(filename)
{
	if (document.implementation && document.implementation.createDocument)
	{
		xmlDoc = document.implementation.createDocument("", "", null);
		xmlDoc.onload = createTable;
	}
	else if (window.ActiveXObject)
	{
		xmlDoc = new ActiveXObject("Microsoft.XMLDOM");
		xmlDoc.onreadystatechange = function () {
			if (xmlDoc.readyState == 4) createTable()
		};
 	}
	else
	{
		alert('Your browser can\'t handle this script');
		return;
	}
	xmlDoc.load(filename);
}

function obj(menu)
{
    return (navigator.appName == "Microsoft Internet Explorer")?this[menu]:document.getElementById(menu);
}

function array_contains(nodes,obj) {
    for (var i = 0; i < nodes.length; i++) {
        if (nodes[i].toString() == obj.toString()) {
           return i;
	}
    }
    return -1;
}
function array_remove(nodes,obj) {
    var index = array_contains(nodes,obj);
    if(index > -1)
        nodes.splice(index, 1);
}
function array_add(nodes,obj) {
    var index = array_contains(nodes,obj);
    if(index == -1)
        nodes.push(obj);
}

function expand(treepart) {

        togglevisible(treepart+"u");
        togglevisible(treepart+"e");
}

function togglevisible(treepart) {

    if (this.obj("T"+treepart).style.visibility == "hidden")
    {
        this.obj("T"+treepart).style.position="";
        this.obj("T"+treepart).style.visibility="";
        /*document["I"+treepart].src="/mediawiki/images/stats_visible.gif";*/
    }
    else
    {
        this.obj("T"+treepart).style.position="absolute";
        this.obj("T"+treepart).style.visibility="hidden";
        /*document["I"+treepart].src="/mediawiki/images/stats_hidden.gif";*/
    }
}

function find_ancestor(obj,tag) {
    var parent = obj;
    while (1) {
        parent = parent.parentNode;
      	if (parent.tagName == tag.toLowerCase() || parent.tagName == tag.toUpperCase())
            return parent;
      	if (parent.tagName == 'HTML' || parent.tagName == 'html')
            return null;
    }
}

function replace(id,str) {
	document.getElementById(id).innerHTML = str ;
}

  </script>
                

  </head>
  <body>

    
<span id="T1u"><a href="javascript:replace(T1u,'a')" border=0>up</a>(test)</span>
<span id="T1e" style="background-color: #efefef; padding-top: 4px; border: 1px solid grey;visibility:hidden"> <span id="T2e" style="background-color: #dddddd; border: 1px solid grey;padding: 1px; margin-top:1px;"> <a href="javascript:expand('1')" border=0>-</a>test3</span></span>


<pre>@body@</pre>

<script language="JavaScript1.2" type="text/javascript">
   @onload@
  </script>
  </body>
  
</html>
