
¶re_sajax_show¶

if (!top.htmltag)
    top.htmltag = { };

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


top.htmltag.obj = function (menu)
{
    return (navigator.appName == "Microsoft Internet Explorer")?this[menu]:document.getElementById(menu);
}


// function saves scroll position
function fScroll(val)
{
    var hidScroll = document.getElementById('hidScroll');
    hidScroll.value = val.scrollTop;
}

// function moves scroll position to saved value
function fScrollMove(what)
{
    var hidScroll = document.getElementById('hidScroll');
    document.getElementById(what).scrollTop = hidScroll.value;
}
	  
window.onbeforeunload = function () {
   // stuff do do before the window is unloaded here.
   //	  alert();
}
	  

function showhide(){
if (document.all||document.getElementById){
if (theobject.style.visibility=="hidden"){
doit=setInterval("positionit()",100)
theobject.style.visibility="visible"
}
else{
theobject.style.visibility="hidden"
clearInterval(doit)
}
}
}

function positionit(){
var dsocleft=document.all? iebody.scrollLeft : pageXOffset
var dsoctop=document.all? iebody.scrollTop : pageYOffset
if (document.all||document.getElementById){
theobject.style.left=dsocleft+"px"
theobject.style.top=dsoctop+"px"
theobject.innerHTML='<big>('+dsocleft+','+dsoctop+')</big>'
}
}
		      
var pathdef = {
    b:     "",
    fids:  new Array(¶re_fids_idx¶),
    paths: new Array()                  
};

var paths = new Array();
¶re_pathinit¶
	
	      
var x_mouse = 0;
var y_mouse = 0;
var z_index = 0;
var isLoaded = 0;

var isIE = document.all?true:false;

if (!isIE) document.captureEvents(Event.MOUSEMOVE);
document.onmousemove = getMousePosition;

function getMousePosition(e) {
        var _x;
        var _y;
        if (!isIE) {
                x_mouse = e.pageX;
                y_mouse = e.pageY;
        }
        if (isIE) {
                x_mouse = document.body.scrollLeft+event.x;
                y_mouse = document.body.scrollTop+event.y;
        }
        return true;
}

function getObj(name) {

        if (document.getElementById){
                this.obj = document.getElementById(name);
                this.style = document.getElementById(name).style;
        } else if (document.all) {
                this.obj = document.all[name];
                this.style = document.all[name].style;
        } else if (document.layers) {
                if (document.layers[name]) {
                        this.obj = document.layers[name];
                        this.style = document.layers[name];
                }
        } else {
                this.obj = document.layers.testP.layers[name];
                this.style = document.layers.testP.layers[name];
        }
}


function totop(treepart) {
        var x = new getObj("T"+treepart);
        x.style.zIndex=z_index++;
}

function show(treepart) {
        if (isLoaded == 0) {
                //display warning
                var x = new getObj("T100000");
                if (x.style.pixelTop && x.style.pixelLeft) {
                        x.style.pixelTop=y_mouse;
                        x.style.pixelLeft=x_mouse;
                } else {
                        x.style.top=y_mouse;
                        x.style.left=x_mouse;
                }
                x.style.zIndex=z_index++;
                x.style.visibility="";
         } else {
                 var x = new getObj("T"+treepart);

                 if (x.style.pixelTop && x.style.pixelLeft) {
                         x.style.pixelTop=y_mouse;
                         x.style.pixelLeft=x_mouse;
                 } else {
                         x.style.top=y_mouse;
                         x.style.left=x_mouse;
                 }
                 x.style.zIndex=z_index++;
                 x.style.visibility="";
         }
}

function hide(treepart) {
        if (isLoaded == 1 || treepart == 100000) {
                var x = new getObj("T"+treepart);
                x.style.visibility="hidden";
        }
}

function setPos(anchor,obj){
         if (isLoaded == 0) {
         } else {
                 var x = new getObj(anchor);
                 var newX = findPosX(x.obj);
                 var newY = findPosY(x.obj);
                 var y = new getObj(obj);
                 y.style.left = newX + 'px';
                 y.style.top = newY + 'px';
         }
         return 1;
}

function findPosX(obj){
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

function findPosY(obj){
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
      


var closednodes = new Array();

      




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

top.htmltag.expand = function (treepart) {

        top.htmltag.togglevisible(treepart+"u");
        top.htmltag.togglevisible(treepart+"e");
}

top.htmltag.toggleshow = function (treepart,finish,arg) {

    if (top.htmltag.obj("T"+treepart) && top.htmltag.obj("T"+treepart).style.visibility == "hidden")
    {
        if (pathdef.paths[treepart]) {
		/*if (top.idx) {
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
		/*if (top.idx) {
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
}




///////////////////////////////////////////////////



// Now for the real thing

var divid = 0;
