# COPYRIGHT:
#
# This software is Copyright (c) 2013 by ovido
#                            (c) 2014 BPView Development Team
#                                     http://github.com/BPView/BPView
#
# This file is part of Business Process View (BPView).
#
# (Except where explicitly superseded by other copyright notices)
# BPView is free software: you can redistribute it and/or modify it 
# under the terms of the GNU General Public License as published by 
# the Free Software Foundation, either version 3 of the License, or 
# any later version.
#
# BPView is distributed in the hope that it will be useful, but WITHOUT 
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or 
# FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License 
# for more details.
#
# You should have received a copy of the GNU General Public License
# along with BPView.  
# If not, see <http://www.gnu.org/licenses/>.

# compiler settings
BINDIR=@bindir@
LIBDIR=@libdir@
CGIDIR=@sbindir@
SYSCONFDIR=@sysconfdir@
LOCALSTATEDIR=@localstatedir@
INSTALL=@INSTALL@
INSTALL_OPTS=@INSTALL_OPTS@
SCRIPT1=bpviewd
SCRIPT2=bpview_reload

# compile
all:
	cp $(SCRIPT1).pl.in $(SCRIPT1).tmp
	sed -i -e 's!lib_path = .*!lib_path = "$(LIBDIR)";!' $(SCRIPT1).tmp
	sed -i -e 's!cfg_path = .*!cfg_path = "$(SYSCONFDIR)";!' $(SCRIPT1).tmp
	sed -i -e 's!log_path = .*!log_path = "$(LOCALSTATEDIR)/log/bpview/";!' $(SCRIPT1).tmp
	sed -i -e 's!pid_path = .*!pid_path = "$(LOCALSTATEDIR)/run/";!' $(SCRIPT1).tmp
	cp $(SCRIPT1).tmp $(SCRIPT1)
	rm -f $(SCRIPT1).tmp
	
	cp $(SCRIPT2).pl.in $(SCRIPT2).tmp
	sed -i -e 's!lib_path = .*!lib_path = "$(LIBDIR)";!' $(SCRIPT2).tmp
	sed -i -e 's!cfg_path = .*!cfg_path = "$(SYSCONFDIR)";!' $(SCRIPT2).tmp
	cp $(SCRIPT2).tmp $(SCRIPT2)
	rm -f $(SCRIPT2).tmp


# install
install:
	for file in $(SCRIPT1) $(SCRIPT2); do \
	  $(INSTALL) -D -m 755 $(INSTALL_OPTS) $$file $(DESTDIR)$(BINDIR)/$$file; \
	done

# cleanup
clean:
	rm -f *.pl
	rm -f $(SCRIPT1)

