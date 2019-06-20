package main

import (
	"fmt"
	"os"
	"regexp"
	"strings"

	"github.com/gocolly/colly"
)

const domain = "downloads.tuxfamily.org"
const rootURL = "https://downloads.tuxfamily.org/godotengine/"

var ignore = map[string]struct{}{
	"apkfixer":         struct{}{},
	"collada-exporter": struct{}{},
	"demos":            struct{}{},
	"media":            struct{}{},
	"patreon":          struct{}{},
	"..":               struct{}{},
}

func main() {
	c := colly.NewCollector(colly.AllowedDomains(domain))
	c.OnHTML("tr", func(e *colly.HTMLElement) {
		typ := e.ChildText("td.t")
		if typ == "Directory" {
			href := e.ChildAttr("td.n a", "href")
			href = strings.TrimRight(href, "/")
			if _, ok := ignore[href]; ok {
				return
			}
			e.Request.Visit(href)
		} else if typ == "application/octet-stream" {
			return
		}
		printVersion(e.ChildText("td.n a"), e.Request.URL.String())
	})
	c.Visit(rootURL)
}

func printVersion(text, url string) {
	if text == "" {
		return
	}
	r := regexp.MustCompile(`(?P<version>Godot_v.+)_(osx|x11).+\.zip`)

	if r.MatchString(text) {
		ver, ok := (findNamedMatches(r, text))["version"]
		if !ok {
			fmt.Fprintf(os.Stderr, "Cannot determine version - naming scheme has changed: %s\n", text)
			os.Exit(1)
		}
		fmt.Printf("%s\t%s\t%s%s\n", strings.TrimLeft(ver, "Godot_"), text, url, text)
	}
}

func findNamedMatches(regex *regexp.Regexp, str string) map[string]string {
	match := regex.FindStringSubmatch(str)

	results := map[string]string{}
	for i, name := range match {
		results[regex.SubexpNames()[i]] = name
	}
	return results
}
