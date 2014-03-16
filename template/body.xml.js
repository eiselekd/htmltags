
¶re_sajax_show¶

if (!top.htmltag)
    top.htmltag = {};
if (!top.htmltag.xml)
    top.htmltag.xml = {};

top.htmltag.xml.replaceXML_onload = function(xmlDoc, xmlid, obj) {
    var onextID = nextID++;
    var x = xmlDoc.getElementsByTagName(xmlid);
    if (x.length > 0 &&
	x[0].childNodes.length > 0 &&
	x[0].nodeType == 1) {
	var y = x[0].getElementsByTagName('line');
	if (y.length > 0 &&
	    y[0].childNodes.length > 0 &&
	    y[0].childNodes[0].nodeType == 3) {
	    var str = new String();
	    for (j=0;j<y.length;j++) {
		for (k=0;k< y[j].childNodes.length;k++) {
		    str += y[j].childNodes[k].nodeValue;
		}
	    }
	    str = str.replace(/--xmlid--/g,onextID+".");
	    top.htmltag.replace(obj,str);
	}
    } else {
	top.htmltag.replace(obj,"<span class=\"parseerror\">Error: Element "+xmlid+" not found</span>");
    }
};

top.htmltag.xml.replaceXML = function (fileid,xmlid,obj,finish,arg) {
    if (document.implementation && document.implementation.createDocument) {
	var xmlDoc = document.implementation.createDocument("", "", null);
	xmlDoc.onload = function() {
	    if ("parsererror" == xmlDoc.documentElement.nodeName) {
		replace(obj,"<span class=\"parseerror\">Parse error: "+xmlDoc.documentElement.firstChild.nodeValue+"</span>");
	    } else {
		top.htmltag.xml.replaceXML_onload(xmlDoc, xmlid, obj);
		if (typeof(finish) == 'function') {
		    finish(arg);
		}
	    }
	};
	xmlDoc.load(fileid);
    } else if (window.ActiveXObject) {
	var xmlDoc = new ActiveXObject("Microsoft.XMLDOM");
	xmlDoc.onreadystatechange = function() {
	    if (xmlDoc.readyState == 4) {
		top.htmltag.xml.replaceXML_onload(xmlDoc, xmlid, obj);
		if (typeof(finish) == 'function') {
		    finish(arg);
		}
	    }
	};
	if (!xmlDoc.load(fileid)) {
	    top.htmltag.replace(obj,"<span class=\"parseerror\">Parse error: "+
		    "errorCode: " + xmlDoc.parseError.errorCode + "\n" +
		    "filepos: "   + xmlDoc.parseError.filepos + "\n" +
		    "line: "      + xmlDoc.parseError.line + "\n" +
		    "linepos: "   + xmlDoc.parseError.linepos + "\n" +
		    "reason: "    + xmlDoc.parseError.reason + "\n" +
		    "srcText: "   + xmlDoc.parseError.srcText + "\n" +
		    "url: "       + xmlDoc.parseError.url +"</span>");
	}
    } else {
	alert('Your browser cant handle load through XMLDOM');
	return;
    }
};
    
/* called from registerd open/close path's */
top.htmltag.xml.replaceXMLpath = function (fileid,xmlid,id,finish,arg) {
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
    top.htmltag.xml.replaceXML(fileid,xmlid,div,finish,arg);
    top.htmltag.markdiv(div,xmlid);
};


top.htmltag.xml.replaceXMLspan = function (elem,fileid,xmlid) {
    var span = top.htmltag.xml.replaceXMLelem("span",elem,fileid,xmlid);
    if (span != null) {
	if (span.className == 'macrou' ||
	    span.className == 'macroe') {
	    var style = new String(xmlid);
	    span.className = 'macro'+style.substr(style.length-1,1);
	}
    }
};

/* called from interactive link */
top.htmltag.xml.replaceXMLdiv = function (elem,fileid,xmlid) {
    var mode = xmlid.substr(xmlid.length-1,1);
    if (mode != 'e' && mode != 'u') {
	alert("Unknown mode "+mode+" from "+xmlid);
    } else {
	var div = top.htmltag.find_ancestor(elem,"div");
	if (div == null) {
	    return;
	}
	top.htmltag.xml.replaceXML(fileid,xmlid,div, function() {
                if (mode == 'e') {
		    if (top.idx)  {
                        top.idx.open('',xmlid.substr(1,xmlid.length-2));
		    }
                } else {
                    if (top.idx)  {
                        top.idx.close('',xmlid.substr(1,xmlid.length-2));
		    }
                } 
            }, mode);					    
	top.htmltag.markdiv(div,xmlid);
    }
};

top.htmltag.xml.replaceXMLelem = function (tag,elem,fileid,xmlid) {
    var obj = top.htmltag.find_ancestor(elem,tag);
    if (obj != null) {
	top.htmltag.xml.replaceXML(fileid,xmlid,obj);
    }
    return obj;
}

top.htmltag.xml.showxmltool = function (thisid, args) {
    var onextID = nextID;
    var argno = ((top.htmltag.xml.showxmltool.arguments.length-1) / 2);
    //alert(document.defaultView.getComputedStyle(document.getElementById(thisid),'').getPropertyValue('top'));
    var tools = top.htmltag.win.CreateDropdownWindow( document.getElementById('A'+thisid) ,"struct", argno, true /*false*/);
    for (i = 0; i < argno; i++) {
	var fileid = top.htmltag.xml.showxmltool.arguments[1+i*2];
	var elemid = top.htmltag.xml.showxmltool.arguments[1+i*2+1];
	top.htmltag.xml.replaceXML(fileid,elemid, tools[i]);				       
    }
}

