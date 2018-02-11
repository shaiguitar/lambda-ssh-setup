# Workaround a tf bug for archiving which does not work with symlinks
# taken from https://github.com/terraform-providers/terraform-provider-archive/issues/6
#
# target: OSX

PATH_TO_ZIP=code
OUTPUT_ZIP_PATH=$(pwd)/ssh_access_lambda.zip

cd $PATH_TO_ZIP
zip -r -X $OUTPUT_ZIP_PATH . %1>/dev/null %2>/dev/null
echo "{ \"hash\": \"$(cat "$ZIP_PATH" | shasum -a 256 | cut -d " " -f 1 | xxd -r -p | base64)\", \"md5\": \"$(cat "$ZIP_PATH" | md5)\" }"
