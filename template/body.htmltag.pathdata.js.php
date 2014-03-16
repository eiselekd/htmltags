<?php
require("cfwSajaxConfig.php");


$mode = "";
if (! empty($_GET["id"])) 
   $mode = "get";
if (!empty($_POST["id"]))
   $mode = "post";
if (empty($mode)) 
   return;

if ($mode == "get") {
    // Bust cache in the head
    header ("Expires: Mon, 26 Jul 1997 05:00:00 GMT");    // Date in the past
    header ("Last-Modified: " . gmdate("D, d M Y H:i:s") . " GMT");
    // always modified
    header ("Cache-Control: no-cache, must-revalidate");  // HTTP/1.1
    header ("Pragma: no-cache");                          // HTTP/1.0
    $id = $_GET["id"];
    $linkid = $_GET["linkid"];

 } else {
    $id = $_POST["id"];
    $linkid = $_POST["linkid"];
 }

echo (getdbentry($id,$linkid));

function getdbentry($id,$linkid) {
        global $sajax_server, $sajax_user, $sajax_pass, $sajax_db, $sajax_table;
        if (!$id) {
                $id = 0;
        }       
        $r = "&lt;not found&gt;";
	if (!($conn = mysql_connect($sajax_server, $sajax_user, $sajax_pass))) {
                return ("Error connecting to $sajax_user:$sajax_pass\@$sajax_server");     
        }
        mysql_select_db($sajax_db);
        
        $query  = "SELECT htmltag_file_path FROM htmltag_file WHERE htmltag_file_fid=$id AND htmltag_file_linkid=$linkid";
        $r = "&lt;not found: $query&gt;";
        $result = mysql_query($query);
        if ($row = mysql_fetch_array($result, MYSQL_ASSOC)) {
                $r = $row['htmltag_file_path'];
        }
	$r = ereg_replace("@","top[document.htmltagid].path",$r);

        mysql_close($conn);
	return $r;
}
    
?>
