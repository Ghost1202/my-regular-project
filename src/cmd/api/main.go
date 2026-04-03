package main

import (

)

func main() {
	app, err := api.NewAppServer()

	if err != nil {
		log.Fatalf("AppServer Error: %s", err.Error())
	}
	defer app.Close()

	if err := app.Start(); err != nil {
		log.Fatalf("%s", err.Error())
	}
}
