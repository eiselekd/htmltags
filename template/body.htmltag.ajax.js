
¶re_sajax_show¶

if (!top.htmltag)
    top.htmltag = {};
if (!top.htmltag.ajax)
    top.htmltag.ajax = {};

top.htmltag.ajax.getdbentry_func = function (onextID,fileid,elemid,rep) {
    var repobj = rep; var id = onextID; 
    top.htmltag.sajax.x_getdbentry(fileid,elemid, function (data) {
	    data = data.replace(/--xmlid--/g,id+".");
	    replace(repobj,data);
	});		
};

/* called from registerd open/close path's */
top.htmltag.ajax.replaceAJAXpath = function (fileid,xmlid,id,finish,arg) {
    var onextID = top.htmltag.win.nextID++;
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
    top.htmltag.sajax.x_getdbentry(fileid,xmlid, function (data) {
	    data = data.replace(/--xmlid--/g,onextID+".");
	    top.htmltag.replace(div,data);
	    if (typeof(finish) == 'function') {
		finish(arg);
	    }
	});
    top.htmltag.markdiv(div,xmlid);
};
	
top.htmltag.ajax.replaceAJAXspan = function (elem,fileid,xmlid) {
    var span = top.htmltag.ajax.replaceAJAXelem("span",elem,fileid,xmlid);
    if (span != null) {
	if (span.className == 'macrou' ||
	    span.className == 'macroe') {
	    var style = new String(xmlid);
	    span.className = 'macro'+style.substr(style.length-1,1);
	}
    }
};

/* called from interactive link */
top.htmltag.ajax.replaceAJAXdiv = function (elem,fileid,xmlid) {
    var onextID = top.htmltag.win.nextID++;
    var mode = xmlid.substr(xmlid.length-1,1);
    if (mode != 'e' && mode != 'u') {
	alert("Unknown mode "+mode+" from "+xmlid);
    } else {
	var div = top.htmltag.find_ancestor(elem,"div");
	if (div == null) {
	    return;
	}
	top.htmltag.sajax.x_getdbentry(fileid,xmlid, function (data) {
		data = data.replace(/--xmlid--/g,onextID+".");
		replace(div,data)
		if (mode == 'e') {
		    if (top.idx) {
			top.idx.open('',xmlid.substr(1,xmlid.length-2));
		    }
		} else {
		    if (top.idx) {
			top.idx.close('',xmlid.substr(1,xmlid.length-2));
		    }
		}
	    });
	top.htmltag.markdiv(div,xmlid);
    }
};

top.htmltag.ajax.replaceAJAXelem = function (tag,elem,fileid,xmlid) {
    var onextID = top.htmltag.win.nextID++;
    var obj = top.htmltag.find_ancestor(elem,tag);
    if (obj != null) {
	top.htmltag.sajax.x_getdbentry(fileid,xmlid, function (data) {
		data = data.replace(/--xmlid--/g,onextID+".");
		top.htmltag.replace(obj,data);
	    });
    }
    return obj;
};
	
top.htmltag.ajax.showajaxtool = function (thisid, args) {
    var onextID = top.htmltag.win.nextID;
    var argno = ((top.htmltag.ajax.showajaxtool.arguments.length-1) / 2);
    var tools = top.htmltag.win.CreateDropdownWindow( document.getElementById('A'+thisid) ,"struct", argno, true /*false*/);
    for (var i = 0; i < argno; i++) {
	var fileid = top.htmltag.ajax.showajaxtool.arguments[1+i*2];
	var elemid = top.htmltag.ajax.showajaxtool.arguments[1+i*2+1];
	var repobj = tools[i];
	top.htmltag.ajax.getdbentry_func(onextID++,fileid,elemid,repobj);
    }
};

