if (typeof(document.htmltagid) == "undefined")
    document.htmltagid = "htmltag";
if (!top[document.htmltagid])
    top[document.htmltagid] = { };
if (!top[document.htmltagid].win)
    top[document.htmltagid].win = {};

// Drag methods
top[document.htmltagid].win.dragObjTitle = null;
top[document.htmltagid].win.dragOffsetX = 0;
top[document.htmltagid].win.dragOffsetY = 0;
top[document.htmltagid].win.topZ = 2;
top[document.htmltagid].win.startX = 100;
top[document.htmltagid].win.startY = 100;
top[document.htmltagid].win.nextID = 1;

top[document.htmltagid].win.CreateDropdownWindow = function (relobj, caption, length, canMove) {

    top[document.htmltagid].win.startX = top[document.htmltagid].x_mouse;
    top[document.htmltagid].win.startY = top[document.htmltagid].y_mouse;
    
    var newdiv;
    var ret = new Array();
    
    
    if (relobj) {
        var left = top[document.htmltagid].win.DL_GetElementLeft(relobj);                              
        var upper = top[document.htmltagid].win.DL_GetElementTop(relobj);
        var height = relobj.offsetHeight;
        top[document.htmltagid].win.startX = left;
        top[document.htmltagid].win.startY = upper+height;
    }                              
                                      
    newdiv = document.createElement("div");
    newdiv.id = "dragTitle" + String(top[document.htmltagid].win.nextID);
    newdiv.className = "divDragTitle";
    newdiv.style.width = 'auto'; //theWidth;
    newdiv.style.left = top[document.htmltagid].win.AddPx(top[document.htmltagid].win.startX);
    newdiv.style.top = top[document.htmltagid].win.AddPx(top[document.htmltagid].win.startY);
    newdiv.style.zIndex = top[document.htmltagid].win.topZ;

    newdiv.innerHTML =   
    '<a class="dragbutton"  href="javascript:top[document.htmltagid].win.CloseContentWin('+top[document.htmltagid].win.nextID+','+length+')">[x]</a><a class="dragbutton" href="javascript:top[document.htmltagid].win.toggleContentWin('+top[document.htmltagid].win.nextID+','+length+')"><span id="'+"dragButton" + String(top[document.htmltagid].win.nextID)+'">[-]</span></a>'
     +'<span class="dragcaption">'+caption+'</span>';
    ;
    
    // If canMove is false, don't register event handlers
    if (canMove) {
        // IE doesn't support addEventListener, so check for its presence
        if (newdiv.addEventListener) {
            // firefox, etc.
            newdiv.addEventListener("mousemove", function(e) { return top[document.htmltagid].win.mouseMove(e) }, true);
            newdiv.addEventListener("mousedown", function(e) { return top[document.htmltagid].win.mouseDown(e) }, true);
            newdiv.addEventListener("mouseup", function(e) { return top[document.htmltagid].win.mouseUp(e) }, true);
        }
        else {
            // IE
            newdiv.attachEvent("onmousemove", function(e) { return top[document.htmltagid].win.mouseMove(e) });
            newdiv.attachEvent("onmousedown", function(e) { return top[document.htmltagid].win.mouseDown(e) });
            newdiv.attachEvent("onmouseup", function(e) { return top[document.htmltagid].win.mouseUp(e) });
        }
    }
    document.body.appendChild(newdiv);

    for (i = 0; i < length; i++) {
        var newdiv2;
        newdiv2 = document.createElement("div");
        newdiv2.id = "dragContent" + String((top[document.htmltagid].win.nextID++)); 
        newdiv2.className = "divDragContent";
        //newdiv2.style.width = 'auto';
        newdiv2.style.left = top[document.htmltagid].win.AddPx(top[document.htmltagid].win.startX);
        newdiv2.style.top = top[document.htmltagid].win.AddPx(top[document.htmltagid].win.startY + 10);
        newdiv2.style.zIndex = top[document.htmltagid].win.topZ;
        
        if (canMove) {
        if (newdiv2.addEventListener) {
            // firefox, etc.
            newdiv2.addEventListener("mousedown", function(e) { return top[document.htmltagid].win.contentMouseDown(e) }, true);
        }
        else {
            // IE
            newdiv2.attachEvent("onmousedown", function(e) { return top[document.htmltagid].win.contentMouseDown(e) });
        }
        }
        newdiv.appendChild(newdiv2);
        ret.push(newdiv2);
    }
                                      
    //document.body.appendChild(newdiv2);
    
    // Save away the content DIV into the title DIV for 
    // later access, and vice versa
    newdiv.content = newdiv2;
    newdiv2.titlediv = newdiv;

    top[document.htmltagid].win.topZ += 1;
    top[document.htmltagid].win.startX += 25;
    top[document.htmltagid].win.startY += 25;
    // If you want you can check when these two are greater than
    // a certain number and then rotate them back to 100,100...
    
    top[document.htmltagid].win.nextID++;
    return ret;				      
};

top[document.htmltagid].win.toggleContentWin = function (id,len) {
    var img = document.getElementById("dragButton" + String(id));
    if (img) {
	if (img.innerHTML == "[-]") {
	    img.innerHTML = "[+]";
	} else {
	    img.innerHTML = "[-]";
	}
    }
    for (var i = 0; i < len; i++) {
	var elem = document.getElementById("dragContent" + String(id+i));
	if (elem) {
	    if (elem.style.display == "none") {
		// hidden, so unhide
		elem.style.display = "block";
	    } else {
		// showing, so hide
		elem.style.display = "none";	    
	    }
	}
    }
};

top[document.htmltagid].win.CloseContentWin = function (id,len) {
    var elem = document.getElementById("dragTitle" + String(id));
    if (elem) {
        elem.parentNode.removeChild(elem);
    } 
};

top[document.htmltagid].win.contentMouseDown = function (e) {
    // Move the window to the front
    // Use a handy trick for IE vs FF
    var dragContent = e.srcElement || e.currentTarget;
    if ( ! dragContent.id.match("dragContent")) {
        dragContent = top[document.htmltagid].win.findParentTagById(dragContent, "dragContent");
    }
    if (dragContent) {
        dragContent.style.zIndex = top[document.htmltagid].win.topZ;
        if (dragContent.titlediv) {
	    dragContent.titlediv.style.zIndex = top[document.htmltagid].win.topZ;
	}
        top[document.htmltagid].win.topZ++;
    }
};

top[document.htmltagid].win.mouseDown = function (e) {
    // These first two lines are written to handle both FF and IE
    var curElem = e.srcElement || e.target;
    var dragTitle = e.currentTarget || top[document.htmltagid].win.findParentDiv(curElem);
    if (dragTitle) {
        if (dragTitle.className != 'divDragTitle') {
            return;
        }
    }
    
    // Start the drag, but first make sure neither is null
    if (curElem && dragTitle) {
    
        // Attach the document handlers. We don't want these running all the time.
        top[document.htmltagid].win.addDocumentHandlers(true);
    
        // Move this window to the front.
        dragTitle.style.zIndex = top[document.htmltagid].win.topZ;
        dragTitle.content.style.zIndex = top[document.htmltagid].win.topZ;
        top[document.htmltagid].win.topZ++;
    
        // Check if it's the button. If so, don't drag.
        if (curElem.className != "divTitleButton") {
            
            // Save away the two objects
            top[document.htmltagid].win.dragObjTitle = dragTitle;
            
            // Calculate the offset
            top[document.htmltagid].win.dragOffsetX = e.clientX - 
                dragTitle.offsetLeft;
            top[document.htmltagid].win.dragOffsetY = e.clientY - 
                dragTitle.offsetTop;
                
            // Don't let the default actions take place
            if (e.preventDefault) {
                e.preventDefault();
            }
            else {
                document.onselectstart = function () { return false; };
                e.cancelBubble = true;
                return false;
            }
        }
    }
};

top[document.htmltagid].win.mouseMove = function (e) {
    // If not null, then we're in a drag
    if (top[document.htmltagid].win.dragObjTitle) {
    
        if (!e.preventDefault) {
            // This is the IE version for handling a strange
            // problem when you quickly move the mouse
            // out of the window and let go of the button.
            if (e.button == 0) {
                top[document.htmltagid].win.finishDrag(e);
                return;
            }
        }
    
        top[document.htmltagid].win.dragObjTitle.style.left = top[document.htmltagid].win.AddPx(e.clientX - top[document.htmltagid].win.dragOffsetX);
        top[document.htmltagid].win.dragObjTitle.style.top = top[document.htmltagid].win.AddPx(e.clientY - top[document.htmltagid].win.dragOffsetY);
        top[document.htmltagid].win.dragObjTitle.content.style.left = top[document.htmltagid].win.AddPx(e.clientX - top[document.htmltagid].win.dragOffsetX);
        top[document.htmltagid].win.dragObjTitle.content.style.top = top[document.htmltagid].win.AddPx(e.clientY - top[document.htmltagid].win.dragOffsetY + 20);
        if (e.preventDefault) {
            e.preventDefault();
        }
        else {
            e.cancelBubble = true;
            return false;
        }
    }
};

top[document.htmltagid].win.mouseUp = function (e) {
    if (top[document.htmltagid].win.dragObjTitle) {
        top[document.htmltagid].win.finishDrag(e);
    }
};

top[document.htmltagid].win.finishDrag = function (e) {
    var finalX = e.clientX - top[document.htmltagid].win.dragOffsetX;
    var finalY = e.clientY - top[document.htmltagid].win.dragOffsetY;
    if (finalX < 0) { finalX = 0 };
    if (finalY < 0) { finalY = 0 };

    top[document.htmltagid].win.dragObjTitle.style.left = top[document.htmltagid].win.AddPx(finalX);
    top[document.htmltagid].win.dragObjTitle.style.top = top[document.htmltagid].win.AddPx(finalY);
    top[document.htmltagid].win.dragObjTitle.content.style.left = top[document.htmltagid].win.AddPx(finalX);
    top[document.htmltagid].win.dragObjTitle.content.style.top = top[document.htmltagid].win.AddPx(finalY + 20);
    
    // Done, so reset to null
    top[document.htmltagid].win.dragObjTitle = null;
    top[document.htmltagid].win.addDocumentHandlers(false);
    if (e.preventDefault) {
        e.preventDefault();
    }
    else {
        document.onselectstart = null;
        e.cancelBubble = true;
        return false;
    }
};

top[document.htmltagid].win.addDocumentHandlers = function (addOrRemove) {
    if (addOrRemove) {
        if (document.body.addEventListener) {
            // firefox, etc.
            document.addEventListener("mousedown", function(e) { return top[document.htmltagid].win.mouseDown(e) }, true);
            document.addEventListener("mousemove", function(e) { return top[document.htmltagid].win.mouseMove(e) }, true);
            document.addEventListener("mouseup", function(e) { return top[document.htmltagid].win.mouseUp(e) }, true);
        }
        else {
            // IE
            document.onmousedown = function() { top[document.htmltagid].win.mouseDown(window.event) } ;
            document.onmousemove = function() { top[document.htmltagid].win.mouseMove(window.event) } ;
            document.onmouseup = function() { top[document.htmltagid].win.mouseUp(window.event) } ;
        }
    }
    else {
        if (document.body.addEventListener) {
            // firefox, etc.
	    /*if (remove) {
                remove.addEventListener("mousedown", function(e) { return mouseDown(e) }, true);
                remove.addEventListener("mousemove", function(e) { return mouseMove(e) }, true);
                remove.addEventListener("mouseup", function(e) { return mouseUp(e) }, true);
	    }*/
        }
        else {
            // IE
            // Be careful here. If you have other code that sets these events,
            // you'll want this code here to restore the values to your other handlers,
            // rather than just clear them out.
            document.onmousedown = null;
            document.onmousemove = null;
            document.onmouseup = null;
        }
    }
};					 

top[document.htmltagid].win.AddPx = function (num) {
    return String(num) + "px";
};

top[document.htmltagid].win.findParentDiv = function (obj) {
    while (obj) {
        if (obj.tagName.toUpperCase() == "DIV") {
            return obj;
        }
        
        if (obj.parentElement) {
            obj = obj.parentElement;
        }
        else {
            return null;
        }
    }
    return null;
};

top[document.htmltagid].win.findParentTagById = function (obj, parentname) {
    while (obj) {
        if (obj.id.match(parentname)) {
            return obj;
        }
        
        if (obj.parentElement) {
            obj = obj.parentElement;
        }
        else {
            return null;
        }
    }
    return null;
};

top[document.htmltagid].win.DL_GetElementLeft = function (eElement)
{
    if (!eElement && this)                       // if argument is invalid
    {                                            // (not specified, is null or is 0)
        eElement = this;                         // and function is a method
    }                                            // identify the element as the method owner
    
    var nLeftPos = eElement.offsetLeft;          // initialize var to store calculations
    var eParElement = eElement.offsetParent;     // identify first offset parent element  
    while (eParElement != null)
    {                                            // move up through element hierarchy
        nLeftPos += eParElement.offsetLeft;      // appending left offset of each parent
        eParElement = eParElement.offsetParent;  // until no more offset parents exist
    }
    return nLeftPos;                             // return the number calculated
}


top[document.htmltagid].win.DL_GetElementTop = function (eElement)
{
    if (!eElement && this)
    {
        eElement = this;
    }

    var nTopPos = eElement.offsetTop;
    var eParElement = eElement.offsetParent;
    while (eParElement != null)
    {
        nTopPos += eParElement.offsetTop;
        eParElement = eParElement.offsetParent;
    }
    return nTopPos;
}
