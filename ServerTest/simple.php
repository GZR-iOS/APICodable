<?php
if (array_key_exists("sleep", $_REQUEST)) {
	$sleep = $_REQUEST["sleep"];
	if ($sleep > 0) {
		sleep($sleep);
	}
}
$info =  array("header" => getallheaders());
$info["method"] = $_SERVER['REQUEST_METHOD'];
$info["params_count"] = count($_REQUEST);
$info["params"] = var_export($_REQUEST, true);
copy("php://input", "Files/RequestBody");
$info["files_count"] = count($_FILES);
$info["files"] = var_export($_FILES, true);
if (count($_FILES) > 0) {
	$info["files"] = $_FILES;
	foreach ($_FILES as $key => $value) {
		$tmpName = $value["tmp_name"];
		if (is_array($tmpName)) {
			$i = 0;
			foreach ($tmpName as $name) {
				copy($name, "Files/" . $key . "-".$i."-". $value["name"][$i]);
				$i += 1;
			}
		} else {
			copy($tmpName, "Files/" . $key . "-" . $value["name"]);
		}
	}
}
header('Content-Type: application/json');
echo json_encode($info, JSON_NUMERIC_CHECK);
?>