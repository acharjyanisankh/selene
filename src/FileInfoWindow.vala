/*
 * FileInfoWindow.vala
 * 
 * Copyright 2012 Tony George <teejee2008@gmail.com>
 * 
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 * 
 * 
 */
 
using Gtk;

public class FileInfoWindow : Dialog {

	private Box vboxMain;
	private Button btnOk;
	public MediaFile file;
	private TreeView tvInfo;
	private ScrolledWindow swInfo;
	
	public FileInfoWindow (MediaFile _file) 
	{
		this.title = "Properties";
		this.file = _file;
		this.deletable = false; // remove window close button
		this.modal = true;
		set_default_size (700, 500);	
		
		// get content area
		vboxMain = get_content_area ();
		vboxMain.margin = 6;
				
		//tvInfo
		tvInfo = new TreeView();
		tvInfo.get_selection().mode = SelectionMode.MULTIPLE;
		tvInfo.set_tooltip_text ("File(s) to convert");
		tvInfo.headers_visible = false;
		tvInfo.insert_column_with_attributes (-1, "Key", new CellRendererText (), "text", 0);
		tvInfo.insert_column_with_attributes (-1, "Value", new CellRendererText (), "text", 1);
		swInfo = new ScrolledWindow(tvInfo.get_hadjustment (), tvInfo.get_vadjustment ());
		swInfo.set_shadow_type (ShadowType.ETCHED_IN);
		swInfo.add (tvInfo);
		swInfo.set_size_request (-1, 200);
		vboxMain.pack_start (swInfo, true, true, 0);

		TreeStore infoStore = new TreeStore (2, typeof (string), typeof (string));

		TreeIter iter0;
		TreeIter iter1;
		int index = -1;
		infoStore.append (out iter0, null);
		infoStore.remove (iter0);
		
		foreach (string line in file.InfoText.split ("\n")){
			if (line.strip () == "") { continue; }
			
			index = line.index_of (":");

			if (index == -1){
				infoStore.append (out iter0, null);
				infoStore.set (iter0, 0, line.strip ());
			}
			else{
				infoStore.append (out iter1, iter0);
				infoStore.set (iter1, 0, line[0:index-1].strip ());
				infoStore.set (iter1, 1, line[index+1:line.length].strip ());
			}
		}
		tvInfo.set_model (infoStore);
		tvInfo.expand_all ();
		
        // btnOk
        btnOk = (Button) add_button (Stock.OK, Gtk.ResponseType.ACCEPT);
        btnOk.clicked.connect (() => {  this.destroy ();  });
	}
}
