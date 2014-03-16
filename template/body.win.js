if (!top.htmltag)
    top.htmltag = { };
if (!top.htmltag.win)
    top.htmltag.win = {};

// Drag methods
top.htmltag.win.dragObjTitle = null;
top.htmltag.win.dragOffsetX = 0;
top.htmltag.win.dragOffsetY = 0;

top.htmltag.win.CreateDropdownWindow = function (relobj, caption, length, canMove) {
    var newdiv;
    var ret = new Array();
    
    startX = x_mouse;
    startY = y_mouse;
    
    if (relobj) {
        var left = DL_GetElementLeft(relobj);                              
        var top = DL_GetElementTop(relobj);
        var height = relobj.offsetHeight;
        startX = left;
        startY = top+height;
    }                              
                                      
    newdiv = document.createElement("div");
    newdiv.id = "dragTitle" + String(nextID);
    newdiv.className = "divDragTitle";
    newdiv.style.width = 'auto'; //theWidth;
    newdiv.style.left = AddPx(startX);
    newdiv.style.top = AddPx(startY);
    newdiv.style.zIndex = topZ;

    newdiv.innerHTML =   
     '<a class="dragbutton"  href="javascript:CloseContentWin('+nextID+')">[x]</a><a class="dragbutton" href="javascript:toggleContentWin('+nextID+')">[-]</a>'
     +'<span class="dragcaption">'+caption+'</span>';
    ;
    
    // If canMove is false, don't register event handlers
    if (canMove) {
        // IE doesn't support addEventListener, so check for its presence
        if (newdiv.addEventListener) {
            // firefox, etc.
            newdiv.addEventListener("mousemove", function(e) { return mouseMove(e) }, true);
            newdiv.addEventListener("mousedown", function(e) { return mouseDown(e) }, true);
            newdiv.addEventListener("mouseup", function(e) { return mouseUp(e) }, true);
        }
        else {
            // IE
            newdiv.attachEvent("onmousemove", function(e) { return mouseMove(e) });
            newdiv.attachEvent("onmousedown", function(e) { return mouseDown(e) });
            newdiv.attachEvent("onmouseup", function(e) { return mouseUp(e) });
        }
    }
    document.body.appendChild(newdiv);

    for (i = 0; i < length; i++) {
        var newdiv2;
        newdiv2 = document.createElement("div");
        newdiv2.id = "dragContent" + String(nextID); nextID++;
        newdiv2.className = "divDragContent";
        //newdiv2.style.width = 'auto';
        newdiv2.style.left = AddPx(startX);
        newdiv2.style.top = AddPx(startY + 10);
        newdiv2.style.zIndex = topZ;
        
        if (canMove) {
        if (newdiv2.addEventListener) {
            // firefox, etc.
            newdiv2.addEventListener("mousedown", function(e) { return contentMouseDown(e) }, true);
        }
        else {
            // IE
            newdiv2.attachEvent("onmousedown", function(e) { return contentMouseDown(e) });
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

    topZ += 1;
    startX += 25;
    startY += 25;
    // If you want you can check when these two are greater than
    // a certain number and then rotate them back to 100,100...
    
    nextID++;
    return ret;				      
};

top.htmltag.win.toggleContentWin = function (id) {
    var elem = document.getElementById("dragContent" + String(id));
    var img = document.getElementById("dragButton" + String(id));

    if (elem.style.display == "none") {
        // hidden, so unhide
        elem.style.display = "block";
        
        // Change the button's image
        img.src = "buttontop.gif";
    } else {
        // showing, so hide
        elem.style.display = "none";

        // Change the button's image
        img.src = "buttonbottom.gif";
    }
};

top.htmltag.win.CloseContentWin = function (id) {
    var elem = document.getElementById("dragTitle" + String(id));
    if (elem) {
        elem.parentNode.removeChild(elem);
    } 
};

top.htmltag.win.contentMouseDown = function (e) {
    // Move the window to the front
    // Use a handy trick for IE vs FF
    var dragContent = e.srcElement || e.currentTarget;
    if ( ! dragContent.id.match("dragContent")) {
        dragContent = findParentTagById(dragContent, "dragContent");
    }
    if (dragContent) {
        dragContent.style.zIndex = topZ;
        if (dragContent.titlediv) {
	    dragContent.titlediv.style.zIndex = topZ;
	}
        topZ++;
    }
};

top.htmltag.win.mouseDown = function (e) {
    // These first two lines are written to handle both FF and IE
    var curElem = e.srcElement || e.target;
    var dragTitle = e.currentTarget || findParentDiv(curElem);
    if (dragTitle) {
        if (dragTitle.className != 'divDragTitle') {
            return;
        }
    }
    
    // Start the drag, but first make sure neither is null
    if (curElem && dragTitle) {
    
        // Attach the document handlers. We don't want these running all the time.
        addDocumentHandlers(true);
    
        // Move this window to the front.
        dragTitle.style.zIndex = topZ;
        dragTitle.content.style.zIndex = topZ;
        topZ++;
    
        // Check if it's the button. If so, don't drag.
        if (curElem.className != "divTitleButton") {
            
            // Save away the two objects
            top.htmltag.win.dragObjTitle = dragTitle;
            
            // Calculate the offset
            top.htmltag.win.dragOffsetX = e.clientX - 
                dragTitle.offsetLeft;
            top.htmltag.win.dragOffsetY = e.clientY - 
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

top.htmltag.win.mouseMove = function (e) {
    // If not null, then we're in a drag
    if (top.htmltag.win.dragObjTitle) {
    
        if (!e.preventDefault) {
            // This is the IE version for handling a strange
            // problem when you quickly move the mouse
            // out of the window and let go of the button.
            if (e.button == 0) {
                finishDrag(e);
                return;
            }
        }
    
        top.htmltag.win.dragObjTitle.style.left = AddPx(e.clientX - top.htmltag.win.dragOffsetX);
        top.htmltag.win.dragObjTitle.style.top = AddPx(e.clientY - top.htmltag.win.dragOffsetY);
        top.htmltag.win.dragObjTitle.content.style.left = AddPx(e.clientX - top.htmltag.win.dragOffsetX);
        top.htmltag.win.dragObjTitle.content.style.top = AddPx(e.clientY - top.htmltag.win.dragOffsetY + 20);
        if (e.preventDefault) {
            e.preventDefault();
        }
        else {
            e.cancelBubble = true;
            return false;
        }
    }
};

top.htmltag.win.mouseUp = function (e) {
    if (top.htmltag.win.dragObjTitle) {
        finishDrag(e);
    }
};

top.htmltag.win.finishDrag = function (e) {
    var finalX = e.clientX - top.htmltag.win.dragOffsetX;
    var finalY = e.clientY - top.htmltag.win.dragOffsetY;
    if (finalX < 0) { finalX = 0 };
    if (finalY < 0) { finalY = 0 };

    top.htmltag.win.dragObjTitle.style.left = AddPx(finalX);
    top.htmltag.win.dragObjTitle.style.top = AddPx(finalY);
    top.htmltag.win.dragObjTitle.content.style.left = AddPx(finalX);
    top.htmltag.win.dragObjTitle.content.style.top = AddPx(finalY + 20);
    
    // Done, so reset to null
    top.htmltag.win.dragObjTitle = null;
    addDocumentHandlers(false);
    if (e.preventDefault) {
        e.preventDefault();
    }
    else {
        document.onselectstart = null;
        e.cancelBubble = true;
        return false;
    }
};

top.htmltag.win.addDocumentHandlers = function (addOrRemove) {
    if (addOrRemove) {
        if (document.body.addEventListener) {
            // firefox, etc.
            document.addEventListener("mousedown", function(e) { return mouseDown(e) }, true);
            document.addEventListener("mousemove", function(e) { return mouseMove(e) }, true);
            document.addEventListener("mouseup", function(e) { return mouseUp(e) }, true);
        }
        else {
            // IE
            document.onmousedown = function() { mouseDown(window.event) } ;
            document.onmousemove = function() { mouseMove(window.event) } ;
            document.onmouseup = function() { mouseUp(window.event) } ;
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
