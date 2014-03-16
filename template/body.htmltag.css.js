if (typeof(document.htmltagid) == "undefined")
    document.htmltagid = "htmltag";
if (!top[document.htmltagid])
    top[document.htmltagid] = {};
if (!top[document.htmltagid].css)
    top[document.htmltagid].css = {};

top[document.htmltagid].css.importCss = function (f) {
    if(document.createStyleSheet) {
	document.createStyleSheet(f);
    } else {
	var styles = "@import url(' "+f+" ');";
	var newSS=document.createElement('link');
	newSS.rel='stylesheet';
	newSS.href='data:text/css,'+escape(styles);
	document.getElementsByTagName("head")[0].appendChild(newSS);
    }
}
    
