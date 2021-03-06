package gitsdees

import (
	"fmt"
	"os"
	"strings"
	"syscall"

	"golang.org/x/crypto/ssh/terminal"
)

// PromptPassword prompts for password and tests against the file in input,
// use "" for no file, in which a new password will be generated
func PromptPassword(gitfolder string, document string) string {
	password1 := "1"
	textToTest, err := GetTextOfOne(gitfolder, "master", "sdees-"+document+".gpg")
	if err != nil {
		fmt.Printf("Creating new document %s\n", document)
		logger.Debug("Error: %s, creating %s", err.Error(), "sdees-"+document+".gpg")
		password2 := "2"
		for password1 != password2 {
			fmt.Printf("Enter new password for %s: ", document)
			bytePassword, _ := terminal.ReadPassword(int(os.Stdin.Fd()))
			password1 = strings.TrimSpace(string(bytePassword))
			fmt.Printf("\nEnter password again: ")
			bytePassword2, _ := terminal.ReadPassword(int(syscall.Stdin))
			password2 = strings.TrimSpace(string(bytePassword2))
			if password1 != password2 {
				fmt.Println("\nPasswords do not match.")
			}
		}
		Passphrase = password1
		_, err := NewDocument(gitfolder, "sdees-"+document, "Yay!", "Added sdees", GetCurrentDate(), "master")
		if err != nil {
			logger.Error("Error creating new document: %s", err.Error())
		}
		Push(gitfolder)
	} else {
		logger.Debug("Testing with master:sdees-%s.gpg", document)
		passwordAccepted := false
		for passwordAccepted == false {
			fmt.Printf("Enter password to open %s: ", document)
			bytePassword, _ := terminal.ReadPassword(int(os.Stdin.Fd()))
			password1 = strings.TrimSpace(string(bytePassword))
			_, err := DecryptString(textToTest, password1)
			if err == nil {
				passwordAccepted = true
			} else {
				fmt.Println("\nPasswords do not match.")
				logger.Debug("Got error: %s", err.Error())
			}
		}
	}
	fmt.Println("")
	return password1
}
