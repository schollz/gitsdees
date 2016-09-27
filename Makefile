SOURCEDIR=.

BINARY=gitsdees

VERSION=2.0.0
BUILD_TIME=`date +%FT%T%z`
BUILD=`git rev-parse HEAD`

LDFLAGS=-ldflags "-X main.Version=${VERSION} -X main.Build=${BUILD} -X main.BuildTime=${BUILD_TIME}"

.DEFAULT_GOAL: $(BINARY)

$(BINARY): $(SOURCES)
	go get github.com/jcelliott/lumber
	go get github.com/mitchellh/go-homedir
	go get github.com/urfave/cli
	go get github.com/jteeuwen/go-bindata/...
	$(GOPATH)/bin/go-bindata bin
	go build ${LDFLAGS} -o ${BINARY}

.PHONY: test
test:
	go get github.com/jcelliott/lumber
	go get github.com/mitchellh/go-homedir
	go get github.com/urfave/cli
	go get github.com/jteeuwen/go-bindata/...
	$(GOPATH)/bin/go-bindata bin
	go test -v -cover

.PHONY: cloc
cloc:
	echo `grep -v "^$$" *.go | grep -v "//" | wc -l` lines of code
	echo `grep -v "^$$" *_test.go | grep -v "//" | wc -l` lines of testing code


.PHONY: install
install:
	sudo mv gitsdees /usr/local/bin/

.PHONY: clean
clean:
	if [ -f ${BINARY} ] ; then rm ${BINARY} ; fi
	rm -rf binaries
	rm -rf tempsdees

.PHONY: windows
windows:
	rm -rf vim*
	wget ftp://ftp.vim.org/pub/vim/pc/vim80w32.zip
	unzip vim80w32.zip
	mv vim/vim80/vim.exe ./src/bin/
	cd src && $(GOPATH)/bin/go-bindata ./bin
	cd src && sed -i -- 's/package main/package gitsdees/g' bindata.go
	mv bindata.go ./src/bindata.go
	env GOOS=windows GOARCH=amd64 go build ${LDFLAGS} -o gitsdees-vim.exe
	cd src && git reset --hard HEAD
	rm -rf ./src/bin/vim.exe

.PHONY: nightly
nightly:
	echo "Deleting old release"
	github-release delete \
	    --user schollz \
	    --repo gitsdees \
	    --tag nightly
	echo "Moving tag"
	git tag --force nightly ${BUILD}
	git push --force --tags
	echo "Creating new release"
	github-release release \
	    --user schollz \
	    --repo gitsdees \
	    --tag nightly \
	    --name "Nightly build" \
	    --description "Autogenerated nightly build of gitsdees" \
	    --pre-release
	echo "Uploading Windows 64 binary"
	env GOOS=windows GOARCH=amd64 go build ${LDFLAGS} -o gitsdees.exe
	github-release upload \
	    --user schollz \
	    --repo gitsdees \
	    --tag nightly \
	    --name "gitsdees-${BUILD}-win64.exe" \
	    --file gitsdees.exe
	rm gitsdees.exe



.PHONY: binaries
binaries:
	go get github.com/jteeuwen/go-bindata/...
	rm -rf binaries
	mkdir binaries
	mkdir bin
	$(GOPATH)/bin/go-bindata bin
	## OS X
	env GOOS=darwin GOARCH=amd64 go build ${LDFLAGS} -o binaries/sdees
	zip -j binaries/sdees_osx_amd64.zip binaries/sdees
	rm binaries/sdees

	## LINUX
	env GOOS=linux GOARCH=amd64 go build ${LDFLAGS} -o binaries/sdees
	zip -j binaries/sdees_linux_amd64.zip binaries/sdees
	rm binaries/sdees
	env GOOS=linux GOARCH=arm go build ${LDFLAGS} -o binaries/sdees
	zip -j binaries/sdees_linux_arm.zip binaries/sdees
	rm binaries/sdees
	env GOOS=linux GOARCH=arm64 go build ${LDFLAGS} -o binaries/sdees
	zip -j binaries/sdees_linux_arm64.zip binaries/sdees
	rm binaries/sdees
	## WINDOWS
	wget ftp://ftp.vim.org/pub/vim/pc/vim80w32.zip
	unzip vim80w32.zip
	mv vim/vim80/vim.exe ./bin/
	rm -rf vim*
	rm -rf bindata.go
	$(GOPATH)/bin/go-bindata bin
	env GOOS=windows GOARCH=amd64 go build ${LDFLAGS} -o binaries/sdees.exe
	zip -j binaries/sdees_windows_amd64.zip binaries/sdees.exe
	rm -rf binaries/vim.exe
	rm -rf ./vim/
	rm binaries/sdees.exe
