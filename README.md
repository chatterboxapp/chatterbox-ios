Chatterbox
=========

Chatterbox is a free and open source instant messaging client for jailbroken iOS. It is adapted from the open source project ChatSecure (https://chatsecure.org) and aims to bring support for features not allowed in sandboxed environments seen outside of jailbroken iOS. It integrates encrypted OTR (https://en.wikipedia.org/wiki/Off-the-Record_Messaging) known as "Off the Record" messaging with support from the libotr (https://otr.cypherpunks.ca/) library and the XMPPFramework (https://github.com/robbiehanson/XMPPFramework/) to handle Jabber/GTalk (XMPP).


Cost
=========

This project is absolutely free. Perhaps consider a donation to the ChatSecure project this is adapted from to continue their great development.


License
=========

	Software License Agreement (GPLv3+)
	
	Copyright (c) 2012, Chris Ballinger. All rights reserved.
	
	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.
	
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this program.  If not, see <http://www.gnu.org/licenses/>.

If you would like to relicense this code to distribute it on the App Store, 
please contact me at [chris@chatsecure.org](mailto:chris@chatsecure.org).


Third-party Libraries
=========

This software additionally references or incorporates the following sources
of intellectual property, the license terms for which are set forth
in the sources themselves:

The following dependencies are bundled with the ChatSecure, but are under
terms of a separate license:

* [libotr](https://otr.cypherpunks.ca/) - provides the core message encryption capabilities
* [libgcrypt](https://www.gnu.org/software/libgcrypt/) - handles core libotr encryption routines
* [libgpg-error](http://www.gnupg.org/related_software/libgpg-error/) - error codes used by libotr
* [LibOrange](https://github.com/unixpickle/LibOrange) - handles all of the OSCAR (AIM) functionality
* [XMPPFramework](https://github.com/robbiehanson/XMPPFramework) - XMPP support
* [MBProgressHUD](https://github.com/jdg/MBProgressHUD) - a nice looking progress HUD
* [MWFeedParser](https://github.com/mwaterfall/MWFeedParser) - Methods for escaping HTML strings
* [Crittercism](https://www.crittercism.com/) - crash reports, only submitted via opt-in
* [SSKeychain](https://github.com/soffes/sskeychain) - Utilities to store passwords securely in the iOS keychain
* [Appirater](https://github.com/arashpayan/appirater) - nags people to give reviews
* [MagicalRecord](https://github.com/magicalpanda/MagicalRecord) - Core Data convenience methods
* [encrypted-core-data](https://github.com/project-imas/encrypted-core-data) - Core Data + SQLCipher
* [UserVoice](https://www.uservoice.com/) - in-app support forum
* [mogenerator](https://github.com/rentzsch/mogenerator) - creates class files for core data model
* [DAKeyboardControl](https://github.com/danielamitay/DAKeyboardControl) - support for swiping down keyboard in chat view

ChatSecure's Acknowledgements
=========

Thank you to everyone who helped this project become a reality! This project is also supported by the fine folks from [The Guardian Project](https://guardianproject.info) and [OpenITP](https://openitp.org).

* [Nick Hum](http://nickhum.com/) - awesome icon.
* [Glyphish](http://glyphish.com/) - icons used on the tab bar.
* [Adium](https://adium.im/) - lock/unlock icon used in chat window, status gems.
* [Sergio Sánchez López](https://www.iconfinder.com/icons/7043/aim_icon) - AIM protocol icon.
* [Mateo Zlatar](http://thenounproject.com/mateozlatar/) - [World Icon](http://thenounproject.com/term/world/6502/)
* [Goxxy](http://rocketdock.com/addon/icons/3462) - Google Talk icon.
* [AcaniChat](https://github.com/acani/AcaniChat) - help on setting up chat view input box
* [Localizations](https://www.transifex.com/projects/p/chatsecure/)
	* [Jiajuan Lin](http://www.personal.psu.edu/jwl5262/blogs/lin_portfolio/) (Chinese)
	* [Jan-Christoph Borchardt](http://jancborchardt.net/) (German)
	* [vitalyster](https://github.com/vitalyster) (Russian)
	* [burhan teoman](https://www.transifex.net/accounts/profile/burhanteoman/) (Turkish)
	* [shikibiomernok](https://www.transifex.net/accounts/profile/shikibiomernok/) (Hungarian)
* Many many more!
