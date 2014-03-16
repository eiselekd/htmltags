if (typeof(document.htmltagid) == "undefined")
    document.htmltagid = "htmltag";
if (!top[document.htmltagid])
    top[document.htmltagid] = { };

top[document.htmltagid].x_mouse = 0;
top[document.htmltagid].y_mouse = 0;
top[document.htmltagid].z_index = 0;
top[document.htmltagid].isLoaded = 0;
top[document.htmltagid].isIE = document.all?true:false;

top[document.htmltagid].markdiv = function (div,xmlid) {
    
    if (div.className == 'fincmarku' ||
	div.className == 'fincmarke') {
	var style = new String(xmlid);
	div.className = 'fincmark'+style.substr(style.length-1,1);
    }				    
};

top[document.htmltagid].find_ancestor = function (obj,tag) {
    var parent = obj;
    while (1) {
	parent = parent.parentNode;
	if (parent == null)
	    return null;
	if (parent.tagName == tag.toLowerCase() || parent.tagName == tag.toUpperCase())
	    return parent;
	if (parent.tagName == 'HTML' || parent.tagName == 'html')
	    return null;
    }
};

top[document.htmltagid].replace = function (obj,str) {
    if (top[document.htmltagid].isIE) {
	str = str.replace(/%0A|\n/g,"<br/>");
    }
    obj.innerHTML = unescape(str);
}

top[document.htmltagid].obj = function (menu) {
    return document.getElementById(menu);
}

top[document.htmltagid].expand = function (treepart) {
        top[document.htmltagid].togglevisible(treepart+"u");
        top[document.htmltagid].togglevisible(treepart+"e");
}

top[document.htmltagid].toggleshow = function (treepart,finish,arg) {

    if (top[document.htmltagid].obj("T"+treepart) && top[document.htmltagid].obj("T"+treepart).style.visibility == "hidden")
    {
        if (top[document.htmltagid].path.pathdef.paths[treepart]) {
		/*if (top.idx && top.idx.open) {
		top.idx.open('',top[document.htmltagid].path.pathdef.paths[treepart].id);
		}*/
        }
        top[document.htmltagid].obj("T"+treepart).style.position="";
        top[document.htmltagid].obj("T"+treepart).style.visibility="";
        /*document["I"+treepart].src="/mediawiki/images/stats_visible.gif";*/
    }
    if (typeof(finish) == 'function') {
	    /*top[document.htmltagid].*/finish(arg);
    }
}

top[document.htmltagid].togglehide = function (treepart,finish,arg) {

    if (top[document.htmltagid].obj("T"+treepart) && top[document.htmltagid].obj("T"+treepart).style.visibility != "hidden") {
        if (top[document.htmltagid].path.pathdef.paths[treepart]) {
		/*if (top.idx && top.idx.close) {
		top.idx.close('',top[document.htmltagid].path.pathdef.paths[treepart].id);
		}*/
        }
        top[document.htmltagid].obj("T"+treepart).style.position="absolute";
        top[document.htmltagid].obj("T"+treepart).style.visibility="hidden";
        /*document["I"+treepart].src="/mediawiki/images/stats_hidden.gif";*/
    }
    if (typeof(finish) == 'function') {
	finish(arg);
    }
}

top[document.htmltagid].togglevisible = function (treepart) {
    
    if (top[document.htmltagid].obj("T"+treepart).style.visibility == "hidden") {
        top[document.htmltagid].toggleshow(treepart);
    } else {
        top[document.htmltagid].togglehide(treepart);
    }
}

top[document.htmltagid].getMousePosition = function (e) {

    var _x;
    var _y;
    if (!top[document.htmltagid].isIE) {
	top[document.htmltagid].x_mouse = e.pageX;
	top[document.htmltagid].y_mouse = e.pageY;
    }
    if (top[document.htmltagid].isIE) {
	top[document.htmltagid].x_mouse = document.body.scrollLeft+event.x;
	top[document.htmltagid].y_mouse = document.body.scrollTop+event.y;
    }
    return true;
};

top[document.htmltagid].findPosX = function (obj) {

    var curleft = 0;
    if (obj.offsetParent) {
	while (obj.offsetParent) {
	    curleft += obj.offsetLeft
		obj = obj.offsetParent;
	}
    }
    else if (obj.x)
	curleft += obj.x;
    return curleft;
}

top[document.htmltagid].findPosY = function (obj) {
    
    var curtop = 0;
    if (obj.offsetParent) {
	while (obj.offsetParent){
	    curtop += obj.offsetTop
		obj = obj.offsetParent;
	}
    }
    else if (obj.y)
	curtop += obj.y;
    return curtop;
}
      




