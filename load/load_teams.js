const axios = require('axios');
const json2csv = require('json2csv');

let offset = 0;
let count = 20;
let teams = [];
axios.get(`http://es01.usfirst.org/teams/_search?size=${count}&from=${offset}&source={%22query%22:{%22filtered%22:{%22query%22:{%22bool%22:{%22must%22:[{%22bool%22:{%22should%22:[[{%22match%22:{%22team_type%22:%22FRC%22}}]]}},{%22bool%22:{%22should%22:[[{%22match%22:{%22fk_program_seasons%22:%22251%22}},{%22match%22:{%22fk_program_seasons%22:%22249%22}},{%22match%22:{%22fk_program_seasons%22:%22253%22}},{%22match%22:{%22fk_program_seasons%22:%22247%22}}]]}}]}}}},%22sort%22:%22team_number_yearly.raw%22}`).then((res) => {
  let teamCount = res.data.hits.total;
  offset += count
  teams = [].concat(teams,res.data.hits.hits.map((t) => t._source));
  let req = []
  while(offset <= teamCount) {
    req.push(axios.get(`http://es01.usfirst.org/teams/_search?size=${count}&from=${offset}&source={%22query%22:{%22filtered%22:{%22query%22:{%22bool%22:{%22must%22:[{%22bool%22:{%22should%22:[[{%22match%22:{%22team_type%22:%22FRC%22}}]]}},{%22bool%22:{%22should%22:[[{%22match%22:{%22fk_program_seasons%22:%22251%22}},{%22match%22:{%22fk_program_seasons%22:%22249%22}},{%22match%22:{%22fk_program_seasons%22:%22253%22}},{%22match%22:{%22fk_program_seasons%22:%22247%22}}]]}}]}}}},%22sort%22:%22team_number_yearly.raw%22}`).then((res) => {
      teams = [].concat(teams,res.data.hits.hits.map((t) => t._source));
    }));
    offset += count;
  }
  axios.all(req).then(() => {
    let fields =  ["team_number_yearly","team_name_calc","team_nickname","team_city","team_stateprov","team_postalcode","profile_year","fk_program_seasons","team_rookieyear","team_web_url","team_country","countryCode","team_type","program_code_display","program_name","lat","lon"];
    teams = teams.map((t) => {
      t.lat = t.location[0].lat;
      t.lon = t.location[0].lon;
      return t;
    })
    let result = json2csv({data:teams, fields});
    console.log(result);
  })

});
