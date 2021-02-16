var https = require('https');
var util = require('util');

exports.handler = function(event, context) {
    console.log(JSON.stringify(event, null, 2));
    console.log('From SNS:', event.Records[0].Sns.Message);

    var postData = {
        "channel": "${slack_channel_name}",
        "username": "AWS",
        "text": "*" + (event.Records[0].Sns.Subject || "Message") + "*",
        "icon_emoji": ":aws:"
    };

    var message = event.Records[0].Sns.Message;
    var severity = "good";

    var skipMessages = [
        "ElastiCache:SnapshotComplete",
        "Finished DB Instance backup",
        "Backing up DB instance",
        "Automated snapshot created",
        "Creating automated snapshot",
        "ElastiCache:CacheClusterProvisioningComplete",
        "ElastiCache:CreateReplicationGroupComplete",
        "ElastiCache:DeleteCacheClusterComplete",
        "Elasticache:ServiceUpdateAvailableForNode"
        ];
        
    var dangerMessages = [
        "ALARM",
        " but with errors",
        " to RED",
        "During an aborted deployment",
        "Failed to deploy application",
        "Failed to deploy configuration",
        "has a dependent object",
        "is not authorized to perform",
        "Pending to Degraded",
        "Stack deletion failed",
        "Unsuccessful command execution",
        "You do not have permission",
        "Your quota allows for 0 more running instance"];

    var warningMessages = [
        " aborted operation.",
        " to YELLOW",
        "Adding instance ",
        "Degraded to Info",
        "Deleting SNS topic",
        "is currently running under desired capacity",
        "Ok to Info",
        "Ok to Warning",
        "Pending Initialization",
        "Removed instance ",
        "Rollback of environment"
        ];
    
    for(var dangerMessagesItem in dangerMessages) {
        if (message.indexOf(dangerMessages[dangerMessagesItem]) != -1) {
            severity = "danger";
            break;
        }
    }
    
    if (severity == "good") {
        for(var warningMessagesItem in warningMessages) {
            if (message.indexOf(warningMessages[warningMessagesItem]) != -1) {
                severity = "warning";
                break;
            }
        }
    }
    
    if (severity == "good") {
        for(var skipMessagesItem in skipMessages) {
            if (message.indexOf(skipMessages[skipMessagesItem]) != -1) {
                return; //skip
            }
        }
    }

    postData.attachments = [
        {
            "color": severity, 
            "text": message
        }
    ];

    var options = {
        method: 'POST',
        hostname: 'hooks.slack.com',
        port: 443,
        path: '${slack_webhook}'
    };

//     Update above path with new webhook path: '/services/T031E6GFG/B4J7SDG5V/EgKK6vhTK6sGuDbOZExS4Skk'


    var req = https.request(options, function(res) {
      console.log('statusCode:', res.statusCode);

      res.setEncoding('utf8');
      res.on('data', function (chunk) {
        context.done(null);
      });
    });
    
    req.on('error', function(e) {
      console.log('problem with request: ' + e.message);
    });    

    req.write(util.format("%j", postData));
    console.log
    req.end();
};
