if (!top.htmltag)
    top.htmltag = { };

top.htmltag.x_mouse = 0;
top.htmltag.y_mouse = 0;
top.htmltag.z_index = 0;
top.htmltag.isLoaded = 0;
top.htmltag.isIE = document.all?true:false;

top.htmltag.markdiv = function (div,xmlid) {
    
    if (div.className == 'fincmarku' ||
	div.className == 'fincmarke') {
	var style = new String(xmlid);
	div.className = 'fincmark'+style.substr(style.length-1,1);
    }				    
};

top.htmltag.find_ancestor = function (obj,tag) {
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

top.htmltag.replace = function (obj,str) {
    if (isIE) {              
	str = str.replace(/%0A/g,"<br/>");
    }
    obj.innerHTML = unescape(str);
}

top.htmltag.obj = function (menu) {
    return (navigator.appName == "Microsoft Internet Explorer")?this[menu]:document.getElementById(menu);
}

top.htmltag.expand = function (treepart) {
        top.htmltag.togglevisible(treepart+"u");
        top.htmltag.togglevisible(treepart+"e");
}

top.htmltag.toggleshow = function (treepart,finish,arg) {

    if (top.htmltag.obj("T"+treepart) && top.htmltag.obj("T"+treepart).style.visibility == "hidden")
    {
        if (pathdef.paths[treepart]) {
	    /*if (top.idx && top.idx.open) {
		top.idx.open('',pathdef.paths[treepart].id);
	    }*/
        }
        top.htmltag.obj("T"+treepart).style.position="";
        top.htmltag.obj("T"+treepart).style.visibility="";
        /*document["I"+treepart].src="/mediawiki/images/stats_visible.gif";*/
    }
    if (typeof(finish) == 'function') {
	top.htmltag.finish(arg);
    }
}

top.htmltag.togglehide = function (treepart,finish,arg) {

    if (top.htmltag.obj("T"+treepart) && top.htmltag.obj("T"+treepart).style.visibility != "hidden") {
        if (pathdef.paths[treepart]) {
	    /*if (top.idx && top.idx.close) {
		top.idx.close('',pathdef.paths[treepart].id);
	    }*/
        }
        top.htmltag.obj("T"+treepart).style.position="absolute";
        top.htmltag.obj("T"+treepart).style.visibility="hidden";
        /*document["I"+treepart].src="/mediawiki/images/stats_hidden.gif";*/
    }
    if (typeof(finish) == 'function') {
	finish(arg);
    }
}

top.htmltag.togglevisible = function (treepart) {
    
    if (top.htmltag.obj("T"+treepart).style.visibility == "hidden") {
        top.htmltag.toggleshow(treepart);
    } else {
        top.htmltag.togglehide(treepart);
    }
}

top.htmltag.getMousePosition = function (e) {

    var _x;
    var _y;
    if (!isIE) {
	top.htmltag.x_mouse = e.pageX;
	top.htmltag.y_mouse = e.pageY;
    }
    if (isIE) {
	top.htmltag.x_mouse = document.body.scrollLeft+event.x;
	top.htmltag.y_mouse = document.body.scrollTop+event.y;
    }
    return true;
}

function top.htmltag.findPosX(obj){

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

function top.htmltag.findPosY(obj){
    
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
      




