if (typeof(document.htmltagid) == "undefined")
    document.htmltagid = "htmltag";
if (!top[document.htmltagid])
    top[document.htmltagid] = { };
if (!top[document.htmltagid].path)
    top[document.htmltagid].path = { };

top[document.htmltagid].path.gotolocation_onload = function ()  {
    var query = (location.href.indexOf("?")+1);
    if (query) {
	var idx = location.href.substr(query);
	if (idx.substr(0,1) == 'D' &&
	    idx.substr(idx.length-2) == "ue") {
	    var target = parseInt(idx.substr(1,idx.length-3))+'';
	    if (typeof(top[document.htmltagid].path.pathdef.paths[target]) != 'undefined') {
		var path = top[document.htmltagid].path.pathdef.paths[target].o;
		var c = new Array();
		for (i in path) {
		    c.push(path[i]);    
		}
		top[document.htmltagid].path.traversepath(c);
	    }
	} else if ( idx.match(/open_([0-9]+)_([0-9]+)/) ) {
	    var fid = RegExp.$1;
	    var id = RegExp.$2;
	    setTimeout(function() {
		    top[document.htmltagid].path.gotolocationopen(0,0,fid,id);
		}, 10);
	} else {
	    alert ("cant decode "+idx);
	}
    }
}

top[document.htmltagid].path.checkfileother = function (fn) {
}

top[document.htmltagid].path.opencloseother = function (fid, openclose) {
    if (openclose) {
	top[document.htmltagid_other].path.locationopen(fid);
    } else {
	top[document.htmltagid_other].path.locationclose(fid);
    }
}

top[document.htmltagid].path.locationclose = function (fid) {
    if (top[document.htmltagid].path.pathdef.paths[fid]) {                                            
	var path = top[document.htmltagid].path.pathdef.paths[fid].c;
	var c = new Array();
	for (i in path) {
	    c.push(path[i]);    
	}
	if (top.location != location &&
	    top.idx) {
	    c.push("top.idx.close('','"+top[document.htmltagid].path.pathdef.paths[fid].id+"'");    
	}
	top[document.htmltagid].path.traversepath(c);
    }
}

top[document.htmltagid].path.locationopen = function (fid) {
    if (top[document.htmltagid].path.pathdef.paths[fid]) {                                            
	var path = top[document.htmltagid].path.pathdef.paths[fid].o;
	var c = new Array();
	for (i in path) {
	    c.push(path[i]);    
	}
	if (top.location != location &&
	    top.idx) {
		//c.push("top.idx.open('','"+top[document.htmltagid].path.pathdef.paths[fid].id+"'");    
	}
	top[document.htmltagid].path.traversepath(c);
    }
}

top[document.htmltagid].path.gotolocationopen = function (elem,sid, fid,id) {
    if (top[document.htmltagid].path.pathdef.paths[fid]) {                                            
	var path = top[document.htmltagid].path.pathdef.paths[fid].o;
	var c = new Array();
	if (sid != -1 && id != 0) {
		c.push("top[document.htmltagid].path.gotolocation("+sid);
	}
	for (i in path) {
	    c.push(path[i]);
	}
	if (id != -1 && id != 0) {
		c.push("top[document.htmltagid].path.gotolocation("+id);
	}
	top[document.htmltagid].path.traversepath(c);
    }
};

top[document.htmltagid].path.gotolocation = function (id,finish,arg) {
    //alert (location);                                    
    if (document.getElementById(id)) {				    
	// document.location.href = '#' + id;
	//location =   '#' + id;				    
	location.hash =   id;				    
    } if (document.getElementsByName(id)) {				    
	//document.location.href = '#' + id;
	//location =  '#' + id;				    
	location.hash =  id;				    
    }
    if (typeof(finish) == "function") {
	finish(arg);
    }
};
					    
top[document.htmltagid].path.traversepath = function (path)  {
    if (path.length > 0) {				    
	var p = path.shift();
	p += ", top[document.htmltagid].path.traversepath, path);";
	eval(p);
    }
}

top[document.htmltagid].path.reload = function (url,fid,aid)  {
	top.main.location.replace(url+"?open_"+fid+"_"+aid);
	setTimeout(function() {
			//top[document.htmltagid_other].path.gotolocationopen(0,-1,fid,aid);
		}, 1000);
}

