// @flow
import Elm from './app.elm'
import 'normalize.css/normalize.css'
import './app.styl'

Elm.App.embed(
  document.getElementById('main')
);
