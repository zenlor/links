(import joy)
(import json)

(def ids
  (generate [_ :iterate true]
            (+ (* 100 (os/mktime))
               (math/floor (* 100 (math/random))))))

# links for poor man
(var links [])

(defn save-links
  [data]
  (set links data)
  (spit "db.json" (json/encode data)))

(defn add-links
  [item]
  (let [data (array/concat @[(merge {:id (resume ids)}
                                   item)]
                           links)]
    (save-links data)))

(defn del-link
  [id]
  (let [data (filter (fn [i] (not= id (i :id)))
                     links)]
    (save-links data)))

#

(defn style
  []
  {:status 200
   :headers {"Content-type" "applicationtext/css"}
   :body "
#links {
    max-width: 400px;
    margin: 0 auto;
}
#links a {
    display: block;
    padding: 22px;

    background-color: #4CAF50; /* Green */
    border: none;
    color: white;

    text-align: center;
    text-decoration: none;
    font-size: 1.4em;
    font-weight: bolder;
    font-variant: small-caps;
}
#links a:hover {
    background-color: #f44336;
}
"})

(defn home
  []
  (joy/text/html
    (joy/doctype :html5)
    [:html {}
     [:head {}
      [:title ""]
      [:link {:href "/style.css" :rel "stylesheet"}]]
     [:body {}
      [:ul {:id "links"}
       (map (fn [i]
              @[:li {}
                [[:a {:href (i :url)} [:text (i :text)]]]
                [:form {:method "post" :action "/"}
                 [:input {:type "hidden" :name "id" :value (i :id)}]
                 [:input {:type "hidden" :name "action" :value "delete"}]
                 [:input {:type "submit"} [:text "del"]]]])
            links)]
      [:hr]
      [:form {:method "post" :action "/"}
       [:input {:type "text" :name "text"}]
       [:input {:type "text" :name "url"}]
       [:input {:type "hidden" :name "action" :value "create"}]
       [:input {:type "submit"} [:text "OK"]]]]]))

(defn parse-form
  [req]
  (def body (joy/http/parse-multipart-body req))
  (def ks (map (fn [i] (i :name)) body))
  (def vs (map (fn [i] (i :content)) body))
  (zipcoll ks vs))

(defn handler [req]
  (print "req")
  (pp req)
  (if (= "POST" (req :method))
    (let [form (parse-form req)]
      (case (form :action
               "delete" (del-link (form :id))
               "create" (add-links form))
        (home)))
    (if (= "/style.css" (req :uri))
      (style)
      (home))))

(defn main [&]
  (when (os/stat "db.json")
    (set links (-> (slurp "db.json")
                   (json/decode true))))
  (joy/server handler
              (or ((os/environ) "PORT")
                  8000)))
