<?php
require("cfwSajax.php");

// Leonardo Lorieri
// My first SAJAX implementention, few lines of inspiration
// A good way to understand SAJAX programming
//
// Work Flow:
// 1- starting by the <body onload="get_date()">
// 2- loading the server's date from the php function,
//      calling the javascript function to show it.
// 3- scheduling another load to the next second
//
// Disclaimer: Hey! I dont speak english
// Under (put your choice here) license


function getdbentry($fid,$id) {
        
        if (!$fid) {
                $fid = 0;
        }       
        $r = "<not found>";
        $sajax_server = "¶re_sajax_server¶";
        $sajax_user   = "¶re_sajax_user¶";
        $sajax_pass   = "¶re_sajax_pass¶";
        $sajax_db     = "¶re_sajax_db¶";
        $sajax_table  = "¶re_sajax_prefix¶_html";

        if (!($conn = mysql_connect($sajax_server, $sajax_user, $sajax_pass))) {
                return ("Error connecting to $sajax_user:$sajax_pass\@$sajax_server");     
        }
        mysql_select_db($sajax_db);
        
        if ($fid >= 0) {
                $query  = "SELECT htmltag_html_text FROM $sajax_table WHERE htmltag_html_fid=$fid AND htmltag_html_name='$id'";
        } else {
                $fid = -$fid;
                $query  = "SELECT htmltag_html_text FROM $sajax_table WHERE htmltag_html_linkid=$fid AND htmltag_html_name='$id'";
        }       
        $r = "<not found: $query>";
        $result = mysql_query($query);
        if ($row = mysql_fetch_array($result, MYSQL_ASSOC)) {
                $r = $row['htmltag_html_text'];
        } 
        mysql_close($conn);
	return $r;
}

//starting CFWSAJAX stuff
$cfwsajax_request_type = "GET";
cfwsajax_init();
cfwsajax_export("getdbentry");
cfwsajax_handle_client_request();
?>

<?php cfwsajax_show_javascript();?> <!--¶re_sajax_show¶-->

if (typeof(document.htmltagid) == "undefined")
    document.htmltagid = "htmltag";
if (!top[document.htmltagid])
    top[document.htmltagid] = {};
if (!top[document.htmltagid].ajax)
    top[document.htmltagid].ajax = {};

top[document.htmltagid].ajax.getdbentry_func = function (onextID,fileid,elemid,rep) {
    var repobj = rep; var id = onextID; 
    x_getdbentry(fileid,elemid, function (data) {
	    data = data.replace(/--xmlid--/g,id+".");
	    top[document.htmltagid].replace(repobj,data);
	});		
};

/* called from registerd open/close path's */
top[document.htmltagid].ajax.replaceAJAXpath = function (fileid,xmlid,id,finish,arg) {
    var onextID = top[document.htmltagid].win.nextID++;
    var div = document.getElementById(id);
    var style = new String();
    style = xmlid.substr(style.length-1,1);
    var n = div.className;				    
    if( n == 'fincmarke' &&
	style == "e") {
	if (typeof(finish) == 'function') {
	    finish(arg);
	}				    
	return;
    }
    x_getdbentry(fileid,xmlid, function (data) {
	    data = data.replace(/--xmlid--/g,onextID+".");
	    top[document.htmltagid].replace(div,data);
	    if (typeof(finish) == 'function') {
		finish(arg);
	    }
	});
    top[document.htmltagid].markdiv(div,xmlid);
};
	
top[document.htmltagid].ajax.replaceAJAXspan = function (elem,fileid,xmlid) {
    var span = top[document.htmltagid].ajax.replaceAJAXelem("span",elem,fileid,xmlid);
    if (span != null) {
	if (span.className == 'macrou' ||
	    span.className == 'macroe') {
	    var style = new String(xmlid);
	    span.className = 'macro'+style.substr(style.length-1,1);
	}
    }
};

/* called from interactive link */
top[document.htmltagid].ajax.replaceAJAXdiv = function (elem,fileid,xmlid) {
    var onextID = top[document.htmltagid].win.nextID++;
    var mode = xmlid.substr(xmlid.length-1,1);
    if (mode != 'e' && mode != 'u') {
	alert("Unknown mode "+mode+" from "+xmlid);
    } else {
	var div = top[document.htmltagid].find_ancestor(elem,"div");
	if (div == null) {
	    return;
	}
	x_getdbentry(fileid,xmlid, function (data) {
		data = data.replace(/--xmlid--/g,onextID+".");
		top[document.htmltagid].replace(div,data)
		if (mode == 'e') {
		    if (top.idx) {
		        top[document.htmltagid].idx._opencloseother(xmlid.substr(1,xmlid.length-2),1);
			//top.idx.open('',xmlid.substr(1,xmlid.length-2));
		    }
		} else {
		    if (top.idx) {
		        top[document.htmltagid].idx._opencloseother(xmlid.substr(1,xmlid.length-2),0);
			//top.idx.close('',xmlid.substr(1,xmlid.length-2));
		    }
		}
	    });
	top[document.htmltagid].markdiv(div,xmlid);
    }
};

top[document.htmltagid].ajax.replaceAJAXelem = function (tag,elem,fileid,xmlid) {
    var onextID = top[document.htmltagid].win.nextID++;
    var obj = top[document.htmltagid].find_ancestor(elem,tag);
    if (obj != null) {
	x_getdbentry(fileid,xmlid, function (data) {
		data = data.replace(/--xmlid--/g,onextID+".");
		top[document.htmltagid].replace(obj,data);
	    });
    }
    return obj;
};
	
top[document.htmltagid].ajax.showajaxtool = function (thisid, args) {
    var onextID = top[document.htmltagid].win.nextID;
    var argno = ((top[document.htmltagid].ajax.showajaxtool.arguments.length-1) / 2);
    var tools = top[document.htmltagid].win.CreateDropdownWindow( document.getElementById('A'+thisid) ,"struct", argno, true /*false*/);
    for (var i = 0; i < argno; i++) {
	var fileid = top[document.htmltagid].ajax.showajaxtool.arguments[1+i*2];
	var elemid = top[document.htmltagid].ajax.showajaxtool.arguments[1+i*2+1];
	var repobj = tools[i];
	top[document.htmltagid].ajax.getdbentry_func(onextID++,fileid,elemid,repobj);
    }
};

