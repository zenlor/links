(import joy)
(import json)

(def ids
  (generate [_ :iterate true]
            (+ (* 100 (os/mktime (os/date)))
               (math/floor (* 100 (math/random))))))

# links for poor man
(var links [])

(defn save-links
  [data]
  (set links data)
  (spit "db.json" (json/encode data)))

(defn add-links
  [{:url url :text text}]
  (let [data (array/concat @[{:id (resume ids)
                              :url url
                              :text text}]
                           links)]
    (save-links data)))

(defn del-link
  [id]
  (def id (scan-number id))
  (let [data (filter (fn [i] (not= id (i :id)))
                     links)]
    (save-links data)))

#
(def stylesheet "
body {
    max-width: 400px;
    margin: 0 auto;
    padding-top: 1em;
    font-family: Iosevka, Comic Sans;
}
#links {
    margin: 0 auto;
    list-style-type: none;
    padding: 0;
}
#links li {
    margin-bottom: 8px;
}
#links a {
    width: 358px;
    height: 40px;
    display: inline-block;
    color: #444;
    text-align: center;
    text-decoration: none;
    font-size: 1.4em;
    font-weight: bolder;
}
#links a:hover {
    text-decoration: #CCC underline 4px;
}
#links form {
    width: 40px;
    display: inline-block;
}
#links form input[type=submit] {
    width: 38px;
    font-weight: bolder;
    font-variant: small-caps;
    background: transparent;
    border: none;
}
hr {
    border: 4px solid #ccc;
}
#insert {}
#ddg {
    display: block;
}
#insert input, #ddg input {
    font-size: 1.1em;
    display: block;
    width: 100%;
    margin-bottom: 0.5em;
    border: none;
    border-bottom: 1px solid #ccc;
}
#insert input[type=submit] {
    margin: 0;
    padding: 6px 0;
    background-color: #f0f0f0;
}
")
(def stylesheet-etag
  (os/mktime (os/date)))
(defn style-head
  []
  {:status 200
   :headers {"Content-type" "text/css"
             "etag" stylesheet-etag}})
(defn style
  []
  {:status 200
   :headers {"Content-type" "text/css"}
   :body stylesheet})

(defn home
  []
  (joy/text/html
    (joy/doctype :html5)
    [:html {}
     [:head {}
      [:title ""]
      [:link {:href "/style.css" :rel "stylesheet"}]]
     [:body {}
      [:form {:method "get" :action "https://lite.duckduckgo.com/lite/" :id "ddg"}
       [:input {:type "text" :name "q" :placeholder "search..."}]]
      [:hr]
      [:ul {:id "links"}
       (map (fn [i]
              @[:li {}
                [[:a {:href (i :url)} [:text (i :text)]]]
                [:form {:method "post" :action "/"}
                 [:input {:type "hidden" :name "id" :value (i :id)}]
                 [:input {:type "hidden" :name "action" :value "delete"}]
                 [:input {:type "submit" :value "x"}]]])
            links)]
      [:hr]
      [:form {:method "post" :action "/" :id "insert"}
       [:input {:type "text" :name "text" :placeholder "title"}]
       [:input {:type "url" :name "url" :placeholder "url"}]
       [:input {:type "hidden" :name "action" :value "create"}]
       [:input {:type "submit" :value "OK"}]]]]))

(defn parse-form
  [req]
  (joy/http/parse-body (req :body)))

(defn handler [req]
  (if (= "POST" (req :method))
    (let [form (parse-form req)]
      (case (form :action)
        "delete" (del-link (form :id))
        "create" (add-links form))
      (home))
    (if (= "/style.css" (req :uri))
      (style)
      (home))))

(defn main [&]
  (when (os/stat "db.json")
    (set links (-> (slurp "db.json")
                   (json/decode true))))
  (joy/server handler
              (or ((os/environ) "PORT")
                  8000)
              (or ((os/environ) "LISTEN")
                  "0.0.0.0")))
