package main

import (
	"fmt"
	"html/template"
	"math/rand"
	"net/http"
	"regexp"
	"strings"
	"sync"
	"time"
)

type FoodEntry struct {
	Name       string
	Attributes map[string][]string
}

var (
	descriptors = []string{
		"delicious", "appetizing", "palatable", "mouth-watering", "tempting",
		"tantalizing", "delectable", "tasty", "daily", "trendy", "scrumptious",
	}

	nouns = []string{
		"choice", "selection", "destination", "delight", "pick",
		"cuisine", "chow", "eats", "bistro", "mecca",
	}

        baseData = []FoodEntry{
		{"China Express", map[string][]string{"time": {"medium"}, "type": {"chineese"}, "cost": {"$"}}},
		{"On the Border", map[string][]string{"time": {"long"}, "type": {"mexican"}, "cost": {"$$$"}}},
		{"Airport Mall", map[string][]string{"time": {"short"}, "type": {"variety"}, "cost": {"$"}}},
		{"Cary Mall Foodcourt", map[string][]string{"time": {"long"}, "type": {"variety"}, "cost": {"$"}}},
		{"Deli Box", map[string][]string{"time": {"short"}, "type": {"deli"}, "cost": {"$$"}}},
		{"El Rodeo", map[string][]string{"time": {"medium"}, "type": {"mexican"}, "cost": {"$"}}},
		{"El Dorado", map[string][]string{"time": {"medium"}, "type": {"mexican"}, "cost": {"$"}}},
		{"Los Tres", map[string][]string{"time": {"medium"}, "type": {"mexican"}, "cost": {"$"}}},
		{"Tico's Pizza", map[string][]string{"time": {"short"}, "type": {"pizza"}, "cost": {"$"}}},
		{"Pizza Inn", map[string][]string{"time": {"medium"}, "type": {"pizza", "buffet"}, "cost": {"$$"}}},
		{"New York Pizza", map[string][]string{"time": {"short"}, "type": {"pizza"}, "cost": {"$$"}}},
		{"35", map[string][]string{"time": {"medium"}, "type": {"chineese", "buffet"}, "cost": {"$$"}}},
		{"Sara's Empenadas", map[string][]string{"time": {"medium"}, "type": {"south american"}, "cost": {"$$"}}},
		{"Wendy's", map[string][]string{"time": {"short"}, "type": {"fastfood"}, "cost": {"$"}}},
		{"Davis BBQ", map[string][]string{"time": {"short"}, "type": {"BBQ"}, "cost": {"$$"}}},
		{"Golden Corral (70)", map[string][]string{"type": {"buffet", "variety"}}},
		{"Golden Corral (54)", map[string][]string{"type": {"buffet", "variety"}}},
		{"Chili's (70)", map[string][]string{"type": {"YABAG"}}},
		{"Chili's (Kildare)", map[string][]string{"type": {"YABAG"}}},
		{"Jersey Mike's", map[string][]string{"type": {"deli"}}},
		{"Pizza Hut (Cary)", map[string][]string{"type": {"pizza"}}},
		{"Ritchie's", map[string][]string{"time": {"short"}, "type": {"deli"}, "cost": {"$$"}}},
		{"1920 Deli", map[string][]string{"time": {"medium"}, "type": {"deli"}}},
		{"Upper Deck", map[string][]string{"type": {"sports bar"}}},
		{"Champions", map[string][]string{"type": {"sports bar"}}},
		{"Woody's", map[string][]string{"type": {"sports bar"}}},
		{"Ragazzi's", map[string][]string{"type": {"italian"}}},
		{"Chic-Fil-A", map[string][]string{"time": {"medium"}, "type": {"fastfood"}, "cost": {"$"}}},
		{"Remmington Grill", map[string][]string{"cost": {"$$"}, "time": {"medium"}, "type": {"YABAG"}}},
		{"Schlotskys", map[string][]string{"cost": {"$$"}, "time": {"medium"}, "type": {"deli"}}},
		{"Arby's", map[string][]string{"cost": {"$"}, "time": {"medium"}, "type": {"sandwich"}}},
		{"Fat Daddy's", map[string][]string{"cost": {"$$"}, "time": {"medium"}, "type": {"burgers"}}},
		{"Waffle House", map[string][]string{"cost": {"$$"}, "time": {"short"}, "type": {"variety"}}},
		{"Cappi's", map[string][]string{"cost": {"$"}, "time": {"short"}, "type": {"deli"}}},
		{"Old Time BBQ", map[string][]string{"cost": {"Damn cheap"}, "time": {"short"}, "type": {"BBQ"}}},
		{"Manhatten", map[string][]string{"cost": {"$$"}, "time": {"medium"}, "type": {"deli"}}},
		{"Texas Steak House", map[string][]string{"cost": {"$$"}, "time": {"short"}, "type": {"Steak"}}},
		{"Ci Ci's pizza", map[string][]string{"cost": {"$"}, "time": {"medium"}, "type": {"pizza"}}},
		{"Harrisons", map[string][]string{"cost": {"$"}, "time": {"medium"}, "type": {"sports bar"}}},
		{"Pizza Pasta Cafe", map[string][]string{"cost": {"$"}, "time": {"medium"}, "type": {"pizza"}}},
		{"Amante", map[string][]string{"cost": {"$"}, "time": {"medium"}, "type": {"pizza"}}},
		{"Torerros", map[string][]string{"cost": {"$"}, "time": {"long"}, "type": {"mexican"}}},
		{"Coyote Cafe", map[string][]string{"cost": {"$$$"}, "time": {"long"}, "type": {"mexican"}}},
		{"Coyote Cafe", map[string][]string{"cost": {"$$$"}, "time": {"long"}, "type": {"mexican"}}},
		{"Bear Rock Cafe", map[string][]string{"cost": {"$"}, "time": {"short"}, "type": {"deli"}}},
		{"D'Nardys", map[string][]string{"cost": {"$$"}, "time": {"short"}, "type": {"variety"}}},
		{"Dakota Grill", map[string][]string{"cost": {"$"}, "time": {"short"}, "type": {"variety"}}},
		{"Rudino's", map[string][]string{"cost": {"$"}, "time": {"medium"}, "type": {"pizza"}}},
		{"Cracker Barrel", map[string][]string{"cost": {"$$"}, "time": {"short"}, "type": {"Bubba"}}},
	}

	validAttributes = map[string]bool{"cost": true, "time": true, "type": true}
	validChars      = regexp.MustCompile(`^[a-zA-Z0-9 .,'&()/-]+$`)
	maxUserEntries  = len(baseData) + 5
	maxAttributes   = 5
	maxFieldLength  = 100
)

func generatePhrase() string {
	desc := descriptors[rand.Intn(len(descriptors))]
	noun := nouns[rand.Intn(len(nouns))]
	return fmt.Sprintf("%s %s", desc, noun)
}

var tmpl = template.Must(template.New("main").Funcs(template.FuncMap{
	"join": strings.Join,
}).Parse(`
<html><head><title>Gastric 8 Ball</title></head><body>
<h1><img src="/8ball/8ball.gif" />Gastric 8 Ball!<img src="/8ball/8ball.gif" /></h1>
<form method="POST">
{{if .Message}}<p style="color: green;"><strong>{{.Message}}</strong></p>{{end}}
{{if .CurrentPick}}
<input type="hidden" name="sucksList" value="{{.SucksList}}">
<p><strong>Today's {{.Phrase}} is: {{.CurrentPick}}</strong></p>
<input type="submit" name="newSuck" value="{{.CurrentPick}} sucks">
{{else if .NoOptions}}
<h2>Looks like the wheel of death for you today.</h2>
<h2>Go play somewhere else.</h2><hr />
{{end}}

<input type="submit" name="action" value="Consult the ball" />
<input type="submit" name="action" value="Suggest a new place" />
<input type="submit" name="action" value="List all places" />

{{if .ShowList}}
<hr />
<h2>Food List</h2>
<table border="1">
<tr>
	<th>Name</th>
	<th>Cost</th>
	<th>Time</th>
	<th>Type</th>
</tr>
{{range .List}}
<tr>
	<td><strong>{{.Name}}</strong></td>
	<td>{{join (index .Attributes "cost") ", "}}</td>
	<td>{{join (index .Attributes "time") ", "}}</td>
	<td>{{join (index .Attributes "type") ", "}}</td>
</tr>
{{end}}
</table>
{{end}}

{{if .ShowAdd}}
<hr />
<h2>Add a new place</h2>
<p>Name: <input name="newname" type="text" /></p>
{{range $key := .ValidAttrs}}
<p>{{$key}}: <input name="new{{$key}}" type="text" /> or <input name="newother{{$key}}" type="text" placeholder="Other" /></p>
{{end}}
<input type="submit" name="action" value="Add it" />
{{end}}
</form>
</body></html>`))

// --- Session Management ---

type session struct {
	Food  []FoodEntry
	Sucks []string
}

var (
	sessionStore = map[string]*session{}
	sessionMutex = sync.Mutex{}
)

func getSession(r *http.Request) *session {
	id := "default" // for now, single shared session. Expand with cookies later.
	sessionMutex.Lock()
	defer sessionMutex.Unlock()
	if s, ok := sessionStore[id]; ok {
		return s
	}
	s := &session{}
	sessionStore[id] = s
	return s
}

func parseSucksList(input string) []string {
	if input == "" {
		return nil
	}
	return strings.Split(input, "	")
}

func processNewEntry(r *http.Request, list *[]FoodEntry) string {
	if len(*list) >= maxUserEntries {
		return "Too many entries added."
	}
	name := r.FormValue("newname")
	if !isSafeName(name) {
		return "Invalid name."
	}
	entry := FoodEntry{Name: name, Attributes: map[string][]string{}}
	for attr := range validAttributes {
		val := r.FormValue("new" + attr)
		if isSafeAttr(attr, val) {
			entry.Attributes[attr] = append(entry.Attributes[attr], val)
		}
		other := r.FormValue("newother" + attr)
		if isSafeAttr(attr, other) {
			entry.Attributes[attr] = append(entry.Attributes[attr], other)
		}
	}
	if len(entry.Attributes) > maxAttributes {
		return "Too many attributes."
	}
	*list = append(*list, entry)
	return "Entry added."
}

func pickRandom(list []FoodEntry, sucks []string) string {
	pool := []string{}
	for _, f := range list {
		skip := false
		for _, s := range sucks {
			if f.Name == s {
				skip = true
				break
			}
		}
		if !skip {
			pool = append(pool, f.Name)
		}
	}
	if len(pool) == 0 {
		return ""
	}
	return pool[rand.Intn(len(pool))]
}

func main() {
	http.HandleFunc("/", handler)
	fmt.Println("Serving on http://localhost:7283")
	http.ListenAndServe(":7283", nil)
}

func init() {
	rand.Seed(time.Now().UnixNano())
}

func isSafeName(v string) bool {
	return len(v) <= maxFieldLength && validChars.MatchString(v)
}

func isSafeAttr(k, v string) bool {
	return validAttributes[k] && len(v) <= maxFieldLength && validChars.MatchString(v)
}

func handler(w http.ResponseWriter, r *http.Request) {
	msg := ""
	sess := getSession(r)
	if sess.Food == nil || len(sess.Food) == 0 {
		sess.Food = make([]FoodEntry, len(baseData))
	copy(sess.Food, baseData)
}


	_ = r.ParseForm()
	sess.Sucks = parseSucksList(r.FormValue("sucksList"))

	if suck := r.FormValue("newSuck"); suck != "" {
		sess.Sucks = append(sess.Sucks, strings.TrimSuffix(suck, " sucks"))
	}

	pick := ""
	phrase := ""
	showList := false
	showAdd := false
	noOptions := false

	if r.Method == http.MethodPost {
		switch r.FormValue("action") {
		case "Add it":
			msg = processNewEntry(r, &sess.Food)
			showList = true
		case "Suggest a new place":
			showAdd = true
		case "List all places":
			showList = true
		case "Consult the ball":
			fallthrough
		default:
			pick = pickRandom(sess.Food, sess.Sucks)
			if pick == "" {
				noOptions = true
			} else {
				phrase = generatePhrase()
			}
		}
	} else {
		pick = pickRandom(sess.Food, sess.Sucks)
		if pick == "" {
			noOptions = true
		} else {
			phrase = generatePhrase()
		}
	}

	tmpl.Execute(w, map[string]interface{}{
		"Message":     msg,
		"List":        sess.Food,
		"CurrentPick": pick,
		"SucksList":   strings.Join(sess.Sucks, "	"),
		"ValidAttrs":  []string{"cost", "time", "type"},
		"ShowList":    showList,
		"ShowAdd":     showAdd,
		"NoOptions":   noOptions,
		"Phrase":      phrase,
	})
}
