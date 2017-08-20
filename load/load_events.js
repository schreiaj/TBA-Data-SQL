const axios = require('axios');
const json2csv = require('json2csv');

let year = parseInt(process.argv[2]);

let offset = 0;
let count = 20;
let events = [];
axios.get(`http://es01.usfirst.org/events/_search?size=${count}&from=${offset}&source={%22query%22:{%22filtered%22:{%22query%22:{%22bool%22:{%22must%22:[{%22bool%22:{%22should%22:[[{%22match%22:{%22event_type%22:%22FRC%22}}]]}},{%22range%22:{%22date_end%22:{%22gte%22:%22${year}-01-20%22,%22lte%22:%22${year}-08-20%22}}}]}}}},%22sort%22:%22event_name.raw%22}`).then((res) => {
  let eventCount = res.data.hits.total;
  offset += count
  events = [].concat(events,res.data.hits.hits.map((e) => e._source));
  let req = []
  while(offset <= eventCount) {
    req.push(axios.get(`http://es01.usfirst.org/events/_search?size=${count}&from=${offset}&source={%22query%22:{%22filtered%22:{%22query%22:{%22bool%22:{%22must%22:[{%22bool%22:{%22should%22:[[{%22match%22:{%22event_type%22:%22FRC%22}}]]}},{%22range%22:{%22date_end%22:{%22gte%22:%22${year}-01-20%22,%22lte%22:%22${year}-08-20%22}}}]}}}},%22sort%22:%22event_name.raw%22}`).then((res) => {
      events = [].concat(events,res.data.hits.hits.map((e) => e._source));
    }));
    offset += count;
  }
  axios.all(req).then(() => {
    events = events.map((e) => {
      e.lat = e.location[0].lat;
      e.lon = e.location[0].lon;
      return e;
    })
    let fields = ["event_name","event_name_analyzed","event_code","fk_program_seasons","event_subtype","event_subtype_moniker","event_type","event_venue","event_venue_sort","event_venue_analyzed","event_stateprov","event_country","event_city","event_address1","event_address2","date_end","date_start","event_postalcode","event_season","capacity_total","event_web_url","flag_bag_and_tag_event","program_code_display","program_name","flag_display_in_vims","ff_event_type_sort_order","countryCode","open_capacity","event_fee_currency","hotel_document","id","lat","lon","event_venue_room","event_fee_base","community_event_contact_name_first","community_event_contact_name_last","community_event_contact_email"];
    let result = json2csv({data:events, fields});
    console.log(result);
  })

});
