
if (typeof(document.htmltagid) == "undefined")
    document.htmltagid = "htmltag";
if (!top[document.htmltagid])
    top[document.htmltagid] = {};
if (!top[document.htmltagid].ajax)
    top[document.htmltagid].ajax = {};

top[document.htmltagid].ajax.getdbentry_func = function (onextID,fileid,elemid,rep,bhtml,ehtml) {
    var _bhtml = bhtml; var _ehtml = ehtml;
    var repobj = rep; var id = onextID; 
    x_getdbentry(fileid,elemid, function (data) {
            data = _bhtml + data + ehtml;
	    data = data.replace(/--xmlid--/g,id+".");
	    top[document.htmltagid].replace(repobj,data);
	});		
};

top[document.htmltagid].ajax.lgetdbentry_func = function (onextID,fileid,elemid,rep,bhtml,ehtml) {
    var _bhtml = bhtml; var _ehtml = ehtml;
    var repobj = rep; var id = onextID; 
    x_lgetdbentry(fileid,elemid, function (data) {
            data = _bhtml + data + ehtml;
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
	if (elemid.substr(0,1) == 'L') {
	  var n = elemid.substr(1);
	  top[document.htmltagid].ajax.lgetdbentry_func(onextID++,fileid,n,repobj,'','');
        } else {	       		
	  top[document.htmltagid].ajax.getdbentry_func(onextID++,fileid,elemid,repobj,'','');
        }
    }
};

top[document.htmltagid].ajax.inlineajaxtool = function (thisid, fileid, elemid) {
    var onextID = top[document.htmltagid].win.nextID++;
    var repobj = document.getElementById('A'+thisid);
    var lobj = document.getElementById('E'+thisid);
    top[document.htmltagid].ajax.getdbentry_func(onextID++,fileid,elemid,repobj,'<div style="margin-left:1.5em;position:relative;" class="fince"><div style="position:absolute;left:-2em;display:inline"><a href="javascript:top[document.htmltagid].ajax.inlineajaxtool()">[-]</a></div>','</div>');
};

