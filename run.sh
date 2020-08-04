#!/bin/sh

INFO="Tested script on serwer"
START_TIME=$(date)
MAIL_FROM_NAME="Test APP"
MAIL_SUBJECT="ALERT"
MAIL_TO="mail@mail.com,tail2@mail.com"                  # , - separator

SMTP_SRV="<smtp servel>"
SMTP_LOGIN="<smtp login>"
SMTP_PASS="<smtp password>"
SMTP_MAIL="<smtp send email>"

MAIL_FILE="tmp.txt"
MAIL_ATTACHMENT_FOLDER="./tmp"

#**********
# Email section
#**********

Email_Init_File () {
     echo 'From: '$MAIL_FROM_NAME' <'$SMTP_MAIL'>
To: '$1'
Subject: '$MAIL_SUBJECT'
CC: '$MAIL_TO'
Content-Type: multipart/mixed; boundary="MixedBoundary"

--MixedBoundary
Content-Type: multipart/related; boundary="AlternativeBoundary"

--AlternativeBoundary
Content-Type: multipart/related; boundary="RelatedBoundary"

--RelatedBoundary
Content-Type: text/html; charset="utf-8"
' >> $MAIL_FILE
     
     Email_Content
     
     echo "
--RelatedBoundary--

--AlternativeBoundary--
" >> $MAIL_FILE

     Email_Attachment

echo "--MixedBoundary--" >> $MAIL_FILE

}

Email_Content () {
     echo "<html>
    <body style=\"font-family: verdana;\">
    </br>
    <div style=\"border-radius: 20px; width: 70%; padding:10px; min-width: 600px; margin: 0 auto; box-sizing:border-box\">
        <div style=\"margin: -10px;border-radius: 20px; padding: 10px; background-color: lightcoral; width: 100%; min-width: 600px; width: calc(100% + 21px);box-sizing:border-box\">
            <h1 style=\"font-size: 200%;width: 100%;text-align: center;\"><b>
                Error Occured
            </b></h1>
            <ul style=\"list-style-type: circle;\">
               <li><b>Time the script was run:</b> "$START_TIME"</li>
               <li><b>Hostname:</b> "$(hostname)"</li>
               <li><b>Info:</b> "$INFO"</li>
            </ul>
        </div>
        <div style=\"margin-top: 30px;box-sizing: border-box;\">
            <p style=\"font-size: 150%;\">
                Error list:
            </p>
            <ul style=\"list-style-type: circle; color: red; font-family: 'Courier New', Courier, monospace;\">
$(cat ERROR_HTML)
            </ul>
        </div>
        
    </div>
    </body>
</html>" >> $MAIL_FILE
}

Email_Attachment () {
     for file in $MAIL_ATTACHMENT_FOLDER/*.txt
     do
          b64_file=$(cat $file | base64)
          filename=$(basename $file)
          echo '--MixedBoundary
Content-Type: text/plain; name="'$filename'"
Content-Transfer-Encoding: base64
Content-Disposition: attachment; filename="'$filename'"

'$b64_file'
' >> $MAIL_FILE
     done
}

Email () {
     for mail in ${MAIL_TO//,/ } ; do 
          Email_Init_File $mail
          curl --ssl-reqd smtp://$SMTP_SRV --mail-from $SMTP_MAIL \
               --mail-rcpt $mail --upload-file $MAIL_FILE \
               --user "$SMTP_LOGIN:$SMTP_PASS"
          rm $MAIL_FILE
     done
}

#**********
# Test section
#**********
Run_Tests () {
     ERROR=0
     for file in ./tests/*
     do
          $file > tmp_msg
          if ! [ $? -eq 0 ]
          then
               local TEST_OUT=$(cat tmp_msg)
               local TEST_NAME=$(basename $file)
               ERROR=1
               local TERM=$(cat $MAIL_ATTACHMENT_FOLDER/$TEST_NAME.txt)
               echo "<li>$TEST_OUT
<pre style=\"background-color: black; color: white; font-family: Courier New, Courier, monospace; border-radius: 3px; width: calc(100% - 20px);\">
$TERM
</pre>
</li>" >> ERROR_HTML
          fi
          rm tmp_msg 
     done
}

#**********
# Run section
#**********

mkdir $MAIL_ATTACHMENT_FOLDER

Run_Tests

if [ $ERROR -eq 1 ]
then
     Email
     rm ERROR_HTML
fi

rm -r $MAIL_ATTACHMENT_FOLDER
