const axios = require('axios');
const json2csv = require('json2csv');
const NodeGeocoder = require('node-geocoder');

const TBA_KEY = process.env.TBA_KEY;
const GOOGLE_KEY = process.env.GOOGLE_KEY;
const BASE_URL = 'http://www.thebluealliance.com/api/v3';

const year = process.argv[2];

let url = `${BASE_URL}/events/${year}/simple`;

axios.get(url, {headers: {'X-TBA-Auth-Key': TBA_KEY}}).then((res) => {
  let events = res.data;
  let geocoder = NodeGeocoder({provider: 'google', apiKey: GOOGLE_KEY});
  let locations = events.map((e) => {
    return `${e.city}, ${e.state_prov} ${e.country}`;
  });
  geocoder.batchGeocode(locations).then((res) => {
    res.map((location, i) => {
      let geocoded = location.value;
      if (geocoded) {
        events[i].lat = geocoded[0].latitude;
        events[i].long = geocoded[0].longitude;
      }
    });
    let fields = ["key", "name", "event_code", "event_type", "city", "state_prov", "country", "start_date", "end_date", "year", "district.display_name", "district.key", "district.year", "district.abbreviation", "lat", "long" ];
    let result = json2csv({data:events, fields});
    console.log(result);
  });


})
