var config = {
  props: ['config'],
  template: `
    <div>
      <h4>Frab Plugin</h4>
      <div class='row'>
        <div class='col-xs-3'>
          <select class='btn btn-default' v-model="mode">
            <option value="all_talks">All Talks</option>
            <option value="next_talk">Next Talk</option>
            <option value="room">Room Name</option>
            <option value="day">Day</option>
          </select>
        </div>
        <div class='col-xs-3'>
          <input
            type="color"
            v-model="color"
            class='form-control'/>
        </div>
        <div class='col-xs-3'>
          <select class='btn btn-default' v-model="font_size">
            <option value="40">40px</option>
            <option value="50">50px</option>
            <option value="60">60px</option>
            <option value="70">70px</option>
            <option value="80">80px</option>
            <option value="90">90px</option>
            <option value="100">100px</option>
            <option value="110">110px</option>
            <option value="150">150px</option>
            <option value="200">200px</option>
          </select>
        </div>
      </div>
      <template v-if='mode == "all_talks"'>
        <h4>All Talks options</h4>
        <div class='row'>
          <div class='col-xs-3'>
            <input
              type="checkbox"
              v-model="all_speakers"
              class='form-check-input'/>
            Show speaker names
          </div>
        </div>
      </template>
      <template v-if='mode == "next_talk"'>
        <h4>Next Talk options</h4>
        <div class='row'>
          <div class='col-xs-3'>
            <input
              type="checkbox"
              v-model="next_abstract"
              class='form-check-input'/>
            Show abstract
          </div>
        </div>
      </template>
      <template v-if='mode == "room"'>
        <h4>room options</h4>
        <div class='row'>
          <div class='col-xs-3'>
            <select class='btn btn-default' v-model="room_align">
              <option value="left">Align left</option>
              <option value="center">Align centered</option>
              <option value="right">Align right</option>
            </select>
          </div>
        </div>
      </template>
      <template v-if='mode == "day"'>
        <h4>Clock options</h4>
        <div class='row'>
          <div class='col-xs-3'>
            <select class='btn btn-default' v-model="day_align">
              <option value="left">Align left</option>
              <option value="center">Align centered</option>
              <option value="right">Align right</option>
            </select>
          </div>
          <div class='col-xs-3'>
            <input
              type="text"
              v-model="day_template"
              placeholder="Template: 'Day %s'"
              class='form-control'/>
          </div>
        </div>
      </template>
    </div>
  `,
  computed: {
    mode: ChildTile.config_value('mode', 'all_talks'),
    color: ChildTile.config_value('color', '#ffffff'),
    font_size: ChildTile.config_value('font_size', 70, parseInt),
    all_speakers: ChildTile.config_value('all_speakers', true),
    next_abstract: ChildTile.config_value('next_abstract', false),
    room_align: ChildTile.config_value('room_align', 'left'),
    day_align: ChildTile.config_value('day_align', 'left'),
    day_template: ChildTile.config_value('day_template', 'Day %d'),
  }
}

ChildTile.register({
  config: config,
});
