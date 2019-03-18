<?php 
	date_default_timezone_set('Europe/Berlin');
	$timestamp	= time();
	$date		= date('Y-m-d',$timestamp);
	$time		= date('H:i:s',$timestamp);
	$status		= filter_var($_GET['status'], FILTER_SANITIZE_STRING);
	$file		= 'NEW40-Log.txt';
	$zipfile	= 'NEW40-Log-'.$timestamp.'.zip';
	$sizemax	= 1024000; 							// 1 MB, then zip it

	if(empty($status)){
		die('No status set, no data written to file');
	}

	# if the $file > than $sizemax, then zip and delete the old textfile
	if (file_exists($file)) {
		$size = filesize($file);
		if ($size > $sizemax) {
			$zip = new ZipArchive;
			if ($zip->open($zipfile, ZipArchive::CREATE) === TRUE){
				$zip->addFile($file);
				$zip->close();
			}
			unlink($file);
		}
	}

	$str		= $date . " | " . $time . " | " . $status . "\n";
	$content	= (file_exists($file)) ? file_get_contents($file) : '';
	$str		= utf8_decode($str);
	$handle		= fopen($file, 'w');

	fwrite($handle, $str . $content);
	fclose($handle);
	exit();
?>