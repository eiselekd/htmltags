if (!top.htmltag)
    top.htmltag = { };
if (!top.htmltag.path)
    top.htmltag.path = { };

top.htmltag.path.gotolocation_onload = function ()  {
    var query = (location.href.indexOf("?")+1);
    if (query) {
	var idx = location.href.substr(query);
	if (idx.substr(0,1) == 'D' &&
	    idx.substr(idx.length-2) == "ue") {
	    var target = parseInt(idx.substr(1,idx.length-3))+'';
	    if (typeof(pathdef.paths[target]) != 'undefined') {
		var path = pathdef.paths[target].o;
		var c = new Array();
		for (i in path) {
		    c.push(path[i]);    
		}
		traversepath(c);
	    }
	} else if ( idx.match(/open_([0-9]+)_([0-9]+)/) ) {
	    var fid = RegExp.$1;
	    var id = RegExp.$2;
	    setTimeout(function() {
		    gotolocationopen(0,0,fid,id);
		}, 10);
	} else {
	    alert ("cant decode "+idx);
	}
    }
}

top.htmltag.path.locationclose = function (fid) {
    if (pathdef.paths[fid]) {                                            
	var path = pathdef.paths[fid].c;
	var c = new Array();
	for (i in path) {
	    c.push(path[i]);    
	}
	if (top.location != location &&
	    top.idx) {
	    c.push("top.idx.close('','"+pathdef.paths[fid].id+"'");    
	}
	traversepath(c);
    }
}

top.htmltag.path.locationopen = function (fid) {
    if (pathdef.paths[fid]) {                                            
	var path = pathdef.paths[fid].o;
	var c = new Array();
	for (i in path) {
	    c.push(path[i]);    
	}
	if (top.location != location &&
	    top.idx) {
		c.push("top.idx.open('','"+pathdef.paths[fid].id+"'");    
	}
	traversepath(c);
    }
}

top.htmltag.path.gotolocationopen = function (elem,sid, fid,id) {
    if (pathdef.paths[fid]) {                                            
	var path = pathdef.paths[fid].o;
	var c = new Array();
	c.push("gotolocation("+sid);    				    
	for (i in path) {
	    c.push(path[i]);    
	}
	c.push("gotolocation("+id);    				    
	traversepath(c);
    }
};


top.htmltag.path.gotolocation = function (id,finish,arg) {
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
					    
top.htmltag.path.traversepath = function (path)  {
    if (path.length > 0) {				    
	var p = path.shift();
	p += ", traversepath, path);";
	eval(p);
    }
}



