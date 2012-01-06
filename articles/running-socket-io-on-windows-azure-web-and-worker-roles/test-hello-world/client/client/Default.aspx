<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8" />
    <title>Client</title>
    <script src="Scripts/socket.io.js" type="text/javascript"></script>
    <script src="Scripts/jquery-1.6.2.js" type="text/javascript"></script>
</head>
<body>
    <div class="page">
        <header>
            <div id="title">
                <h3>Click to introduce yourself</h3>
            </div>
        </header>
        <section id="main">
            <input id="startButton" type="button" value="Say hello!" />
            <label id="returnMessageLabel" style="height:25px"></label>
        </section>
        <footer>
        </footer>
    </div>
    <script type="text/javascript">
        $(document).ready(function () {
            $("#startButton").click(function () {
                var socket = io.connect("http://localhost:81/");
                socket.on('sayHello', function (data) {
                    $("#returnMessageLabel").text(data.message);
                });
            });
        });  
    </script>
</body>
</html>
