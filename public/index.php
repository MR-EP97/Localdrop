<?php

$shareDir = __DIR__ . '/../share'; 

if (!file_exists($shareDir)) {
    mkdir($shareDir, 0777, true);
}

if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_FILES['file'])) {
    $uploadFile = $shareDir . '/' . basename($_FILES['file']['name']);
    move_uploaded_file($_FILES['file']['tmp_name'], $uploadFile);
    header("Location: index.php");
    exit;
}

$files = array_diff(scandir($shareDir), ['.', '..']);
?>

<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Simple Share App</title>
    <!-- <style>
        body { font-family: Arial; padding: 20px; }
        .file { margin-bottom: 10px; }
        .file a { text-decoration: none; color: #333; }
        .upload { margin-top: 30px; }
    </style> -->
    <link rel="stylesheet" href="style.css">
</head>
<body>

<div class="container">
        <div class="file-list">
             <h2>Shared Files</h2>

            <?php if (empty($files)): ?>
                <p id="no-file" >No files uploaded yet.</p>
            <?php else: ?>
                <ul>
                <?php foreach ($files as $file): ?>
                    <li class="file">
                        <?php echo htmlspecialchars($file); ?>
                        — <a href="download.php?file=<?php echo urlencode($file); ?>" download>Download</a>
                    </li>
                <?php endforeach; ?>
                </ul>
            <?php endif; ?>
        </div>
        <div class="upload">
                <h3>Upload a File</h3>
                <form method="post" enctype="multipart/form-data">
                    <!-- <input type="file" name="file" required> -->
                    <div class="choose">
                        <label for="file-upload" class="custom-file-upload">
                            <img src="img/icons8-add-file-48.png" id="upload-icon">
                            <span>choose file</span> 
                        </label>
                        <input type="file" name="file" id="file-upload" hidden required />
                        
                    </div>
                         <button type="submit" >Upload</button>
                </form>
        </div>
    <div>
</body>
</html>
