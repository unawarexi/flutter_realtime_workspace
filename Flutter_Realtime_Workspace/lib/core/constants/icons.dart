import 'package:iconsax/iconsax.dart';
import 'package:flutter/material.dart';

/// Centralised icon mapping so screens never reference raw icon values directly.
class SIcons {
  SIcons._();

  // ── Navigation ───────────────────────────────────────────────
  static const home = Iconsax.home;
  static const homeActive = Iconsax.home_15;
  static const projects = Iconsax.task_square;
  static const projectsActive = Iconsax.task_square5;
  static const teams = Iconsax.people;
  static const teamsActive = Iconsax.people5;
  static const dashboard = Iconsax.chart_square;
  static const dashboardActive = Iconsax.chart_square5;
  static const profile = Iconsax.user;
  static const profileActive = Iconsax.user5;

  // ── Actions ──────────────────────────────────────────────────
  static const add = Iconsax.add;
  static const edit = Iconsax.edit;
  static const delete = Iconsax.trash;
  static const search = Iconsax.search_normal;
  static const filter = Iconsax.filter;
  static const sort = Iconsax.arrow_swap_horizontal;
  static const notification = Iconsax.notification;
  static const notificationActive = Iconsax.notification5;
  static const settings = Iconsax.setting_2;
  static const settingsActive = Iconsax.setting_25;
  static const menu = Iconsax.menu;
  static const close = Icons.close;
  static const back = Icons.arrow_back_ios_new;
  static const more = Iconsax.more_circle;
  static const refresh = Iconsax.refresh;
  static const send = Iconsax.send_1;
  static const attach = Iconsax.attach_circle;
  static const share = Iconsax.export_2;
  static const copy = Iconsax.copy;
  static const download = Iconsax.arrow_circle_down;
  static const upload = Iconsax.arrow_circle_up;

  // ── Auth ─────────────────────────────────────────────────────
  static const email = Iconsax.sms;
  static const password = Iconsax.lock;
  static const passwordVisible = Iconsax.eye;
  static const passwordHidden = Iconsax.eye_slash;
  static const biometric = Iconsax.finger_scan;
  static const google = Icons.g_mobiledata;
  static const github = Icons.code;
  static const microsoft = Icons.window;

  // ── Project / Task ───────────────────────────────────────────
  static const task = Iconsax.task;
  static const taskComplete = Iconsax.task_square5;
  static const calendar = Iconsax.calendar;
  static const calendarAdd = Iconsax.calendar_add;
  static const deadline = Iconsax.timer_1;
  static const priority = Iconsax.flag;
  static const label = Iconsax.tag;
  static const milestone = Iconsax.map_1;
  static const gantt = Iconsax.chart_1;
  static const board = Iconsax.kanban;
  static const timeline = Iconsax.graph;
  static const issue = Iconsax.warning_2;

  // ── Collaboration ────────────────────────────────────────────
  static const chat = Iconsax.message;
  static const chatActive = Iconsax.message5;
  static const call = Iconsax.call;
  static const videoCall = Iconsax.video;
  static const meeting = Iconsax.people;
  static const document = Iconsax.document;
  static const file = Iconsax.folder;
  static const image = Iconsax.image;

  // ── Account ──────────────────────────────────────────────────
  static const account = Iconsax.user_octagon;
  static const invite = Iconsax.user_add;
  static const privacy = Iconsax.shield_tick;
  static const support = Iconsax.headphone;
  static const feedback = Iconsax.message_favorite;
  static const rate = Iconsax.star;
  static const whatsNew = Iconsax.flash;
  static const logout = Iconsax.logout;
  static const theme = Iconsax.sun_1;

  // ── Status / Feedback ────────────────────────────────────────
  static const success = Icons.check_circle_outline;
  static const error = Iconsax.warning_2;
  static const info = Iconsax.info_circle;
  static const warning = Icons.warning_amber_rounded;
  static const loading = Icons.hourglass_empty;
  static const offline = Iconsax.wifi_square;
  static const online = Iconsax.wifi;

  // ── Misc ─────────────────────────────────────────────────────
  static const location = Iconsax.location;
  static const clock = Iconsax.clock;
  static const link = Iconsax.link;
  static const star = Iconsax.star;
  static const starFilled = Iconsax.star5;
  static const chart = Iconsax.chart_2;
  static const analytics = Iconsax.activity;
  static const referral = Iconsax.gift;
}
