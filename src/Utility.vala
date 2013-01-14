/*
 * Utility.vala
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

/*
public const string AppName = "Selene Media Encoder";
public const string AppVersion = "1.0";
public const bool LogTimestamp = true;
*/

public void log_msg (string message, bool highlight = false)
{
	string msg = "";
	
	if (highlight && UseConsoleColors){
		msg += "\033[1;38;5;34m";
	}
	
	if (LogTimestamp){
		msg += "[" + Utility.timestamp() +  "] ";
	}
	
	msg += message;
	
	if (highlight && UseConsoleColors){
		msg += "\033[0m";
	}
	
	msg += "\n";
	
	stdout.printf (msg);
}

public void log_error (string message, bool highlight = false)
{
	string msg = "";
	
	if (highlight && UseConsoleColors){
		msg += "\033[1;38;5;160m";
	}
	
	if (LogTimestamp){
		msg += "[" + Utility.timestamp() +  "] ";
	}
	
	msg += "Error: " + message;
	
	if (highlight && UseConsoleColors){
		msg += "\033[0m";
	}
	
	msg += "\n";
	
	stderr.printf (msg);
}

namespace Utility 
{
	public void messagebox_show(string title, string message, bool is_error = false)
	{
		Gtk.MessageType type = Gtk.MessageType.INFO;
		
		if (is_error)
			type = Gtk.MessageType.ERROR;
			
		var dialog = new Gtk.MessageDialog(null,Gtk.DialogFlags.MODAL, type, Gtk.ButtonsType.OK, message);
		dialog.set_title(title);
		dialog.run();
		dialog.destroy();
	}	
	
	public void file_delete(string filePath)
	{
		try {
			var file = File.new_for_path (filePath);
			if (file.query_exists ()) { 
				file.delete (); 
			}
		} catch (Error e) {
	        log_error (e.message);
	    }
	}
	
	public string timestamp2 ()
	{
		return "%ld".printf((long) time_t ());
	}
	
	public string timestamp ()
	{
		Time t = Time.local (time_t ());
		return t.format ("%H:%M:%S");
	}
	
	public string format_file_size (int64 size)
	{
		return "%0.1f MB".printf (size / (1024.0 * 1024));
	}
	
	public string format_duration (long millis)
	{
	    double time = millis / 1000.0; // time in seconds

	    double hr = time / (60.0 * 60);
	    time = time - (Math.floor (hr) * 60 * 60);
	    double min = time / (60.0);
	    time = time - (Math.floor (min) * 60);
	    double sec = time;
	    
        return "%02.0lf:%02.0lf:%02.0lf".printf (hr, min, sec);
	}
	
	public double parse_time (string time)
	{
		string[] arr = time.split (":");
		double millis = 0;
		if (arr.length >= 3){
			millis += double.parse(arr[0]) * 60 * 60;
			millis += double.parse(arr[1]) * 60;
			millis += double.parse(arr[2]);
		}
		return millis;
	}
	
	public long get_file_duration(string filePath)
	{
		string output = "0";
		
		try {
			Process.spawn_command_line_sync("mediainfo \"--Inform=General;%Duration%\" " + double_quote (filePath), out output);
		}
		catch(Error e){
	        log_error (e.message);
	    }
	    
		return long.parse(output);
	}
	
	public string get_file_crop_params (string filePath)
	{
		string output = "";
		string error = "";
		
		try {
			Process.spawn_command_line_sync("avconv -i " + double_quote (filePath) + " -vf cropdetect=30 -ss 5 -t 5 -f matroska -an -y /dev/null", out output, out error);
		}
		catch(Error e){
	        log_error (e.message);
	    }
	    
	    int w=0,h=0,x=10000,y=10000;
		int num=0;
		string key,val;
	    string[] arr;
	    
	    foreach (string line in error.split ("\n")){
			if (line == null) { continue; }
			if (line.index_of ("crop=") == -1) { continue; }
			
			foreach (string part in line.split (" ")){
				if (part == null || part.length == 0) { continue; }
				
				arr = part.split (":");
				if (arr.length != 2) { continue; }
				
				key = arr[0].strip ();
				val = arr[1].strip ();
				
				switch (key){
					case "x":
						num = int.parse (arr[1]);
						if (num < x) { x = num; }
						break;
					case "y":
						num = int.parse (arr[1]);
						if (num < y) { y = num; }
						break;
					case "w":
						num = int.parse (arr[1]);
						if (num > w) { w = num; }
						break;
					case "h":
						num = int.parse (arr[1]);
						if (num > h) { h = num; }
						break;
				}
			}
		}
		
		if (x == 10000 || y == 10000)
			return "%i:%i:%i:%i".printf(0,0,0,0);
		else 
			return "%i:%i:%i:%i".printf(w,h,x,y);
	}
	
	public string get_mediainfo (string filePath)
	{
		string output = "";
		
		try {
			Process.spawn_command_line_sync("mediainfo " + double_quote (filePath), out output);
		}
		catch(Error e){
	        log_error (e.message);
	    }
	    
		return output;
	}
	
	public long[] get_process_children (Pid parentPid)
	{
		string output;
		
		try {
			Process.spawn_command_line_sync("ps --ppid " + parentPid.to_string(), out output);
		}
		catch(Error e){
	        log_error (e.message);
	    }
			
		long pid;
		long[] procList = {};
		string[] arr;
		
		foreach (string line in output.split ("\n")){
			arr = line.strip().split (" ");
			if (arr.length < 1) { continue; }
			
			pid = 0;
			pid = long.parse (arr[0]);
			
			if (pid != 0){
				procList += pid;
			}
		}
		return procList;
	}
	
	public void process_kill(Pid process_pid, bool killChildren = true)
	{
		long[] child_pids = get_process_children (process_pid);
		Posix.kill (process_pid, 15);
		
		if (killChildren){
			Pid childPid;
			foreach (long pid in child_pids){
				childPid = (Pid) pid;
				Posix.kill (childPid, 15);
			}
		}
	}
	
	public void process_set_priority (Pid procID, int prio)
	{
		if (Posix.getpriority (Posix.PRIO_PROCESS, procID) != prio)
			Posix.setpriority (Posix.PRIO_PROCESS, procID, prio);
	}
	
	public int process_get_priority (Pid procID)
	{
		return Posix.getpriority (Posix.PRIO_PROCESS, procID);
	}
	
	public void process_set_priority_normal (Pid procID)
	{
		process_set_priority (procID, 0);
	}
	
	public void process_set_priority_low (Pid procID)
	{
		process_set_priority (procID, 5);
	}
	
	public bool file_exists (string filePath)
	{
		return ( FileUtils.test(filePath, GLib.FileTest.EXISTS) && FileUtils.test(filePath, GLib.FileTest.IS_REGULAR));
	}
	
	public bool dir_exists (string filePath)
	{
		return ( FileUtils.test(filePath, GLib.FileTest.EXISTS) && FileUtils.test(filePath, GLib.FileTest.IS_DIR));
	}
	
	public bool create_dir (string filePath)
	{
		try{
			var dir = File.parse_name (filePath);
			if (dir.query_exists () == false) {
				dir.make_directory (null);
			}
			return true;
		}
		catch (Error e) { 
			log_error (e.message); 
			return false;
		}
	}
	
	public bool move_file (string sourcePath, string destPath)
	{
		try{
			File fromFile = File.new_for_path (sourcePath);
			File toFile = File.new_for_path (destPath);
			fromFile.move (toFile, FileCopyFlags.NONE);
			return true;
		}
		catch (Error e) { 
			log_error (e.message); 
			return false;
		}
	}
	
	public bool copy_file (string sourcePath, string destPath)
	{
		try{
			File fromFile = File.new_for_path (sourcePath);
			File toFile = File.new_for_path (destPath);
			fromFile.copy (toFile, FileCopyFlags.NONE);
			return true;
		}
		catch (Error e) { 
			log_error (e.message); 
			return false;
		}
	}
	
	public string resolve_relative_path (string filePath)
	{
		string filePath2 = filePath;
		if (filePath2.has_prefix ("~")){
			filePath2 = Environment.get_home_dir () + "/" + filePath2[2:filePath2.length];
		}
		
		try {
			string output = "";
			Process.spawn_command_line_sync("realpath " + double_quote (filePath2), out output);
			output = output.strip ();
			if (FileUtils.test(output, GLib.FileTest.EXISTS)){
				return output;
			}
		}
		catch(Error e){
	        log_error (e.message);
	    }
	    
	    return filePath2;
	}
	
	public bool user_is_admin ()
	{
		try{
			// create a process
			string[] argv = { "sleep", "10" };
			Pid procId;
			Process.spawn_async(null, argv, null, SpawnFlags.SEARCH_PATH, null, out procId); 
			
			// try changing the priority
			Posix.setpriority (Posix.PRIO_PROCESS, procId, -5);
			
			// check if priority was changed successfully
			if (Posix.getpriority (Posix.PRIO_PROCESS, procId) == -5)
				return true;
			else
				return false;
		} 
		catch (Error e) { 
			log_error (e.message); 
			return false;
		}
	}
	
	public int get_pid_by_name (string name)
	{
		try{
			string output = "";
			Process.spawn_command_line_sync("pidof " + double_quote (name), out output);
			if (output != null){
				string[] arr = output.split ("\n");
				if (arr.length > 0){
					return int.parse (arr[0]);
				}
			}
		} 
		catch (Error e) { 
			log_error (e.message); 
		}
		
		return -1;
	}
	
	public bool shutdown ()
	{
		try{
			string[] argv = { "shutdown", "-h", "now" };
			Pid procId;
			Process.spawn_async(null, argv, null, SpawnFlags.SEARCH_PATH, null, out procId); 
			return true;
		} 
		catch (Error e) { 
			log_error (e.message); 
			return false;
		}
	}
	
	public string double_quote (string txt)
	{
		return "\"" + txt.replace ("\"","\\\"") + "\"";
	}

	public int execute_command_sync (string cmd)
	{
		try {
			int exitCode;
			Process.spawn_command_line_sync(cmd, null, null, out exitCode);
	        return exitCode;
		}
		catch (Error e){
	        log_error (e.message);
	        return -1;
	    }
	}
	
	public string execute_command_sync_get_output (string cmd)
	{
		try {
			int exitCode;
			string std_out;
			Process.spawn_command_line_sync(cmd, out std_out, null, out exitCode);
	        return std_out;
		}
		catch (Error e){
	        log_error (e.message);
	        return "";
	    }
	}
	
	public bool execute_command_async (string cmd)
	{
		try {
			
			string scriptfile = create_temp_bash_script ("#!/bin/bash\n" + cmd);
			
			string[] argv = new string[1];
			argv[0] = scriptfile;
			
			Pid child_pid;
			Process.spawn_async_with_pipes(
			    null, //working dir
			    argv, //argv
			    null, //environment
			    SpawnFlags.SEARCH_PATH,
			    null,
			    out child_pid);
			return true;
		}
		catch (Error e){
	        log_error (e.message);
	        return false;
	    }
	}
	
	public string? create_temp_bash_script (string cmd)
	{
		string script_path = Environment.get_tmp_dir () + "/" + timestamp2() + ".sh";

		if (write_file (script_path, cmd)){  // create file
			chmod (script_path, "u+x");      // set execute permission
			return script_path;
		}
		else{
			return null;
		}
	}
	
	public string? read_file (string file_path)
	{
		string txt;
		size_t size;
		
		try{
			GLib.FileUtils.get_contents (file_path, out txt, out size);
			return txt;	
		}
		catch (Error e){
	        log_error (e.message);
	    }
	    
	    return null;
	}
	
	public bool write_file (string file_path, string contents)
	{
		try{
			var file = File.new_for_path (file_path);
			var file_stream = file.create (FileCreateFlags.REPLACE_DESTINATION);
			var data_stream = new DataOutputStream (file_stream);
			data_stream.put_string (contents);
			data_stream.close();
			return true;
		}
		catch (Error e) {
	        log_error (e.message);
	        return false;
	    } 
	}
	
	public bool execute_command_script_in_terminal_sync (string script)
	{
		try {
			
			string[] argv = new string[3];
			argv[0] = "x-terminal-emulator";
			argv[1] = "-e";
			argv[2] = script;
		
			Process.spawn_sync (
			    Environment.get_tmp_dir (), //working dir
			    argv, //argv
			    null, //environment
			    SpawnFlags.SEARCH_PATH,
			    null   // child_setup
			    );
			    
			return true;
		}
		catch (Error e){
	        log_error (e.message);
	        return false;
	    }
	}
	
	public void setting_read (string section, string key)
	{
		//string config_file = get_app_dir () + "/config";
		//string txt = read_file (config_file);
		
		//string section
	}
	
	public void setting_write (string section, string key)
	{
		
	}
	
	public string get_app_path ()
	{
		try{
			return GLib.FileUtils.read_link ("/proc/self/exe");	
		}
		catch (Error e){
	        log_error (e.message);
	        return "";
	    }
	}
	
	public string get_app_dir ()
	{
		try{
			return (File.new_for_path (GLib.FileUtils.read_link ("/proc/self/exe"))).get_parent ().get_path ();	
		}
		catch (Error e){
	        log_error (e.message);
	        return "";
	    }
	}
	
	public int exo_open (string txt)
	{
		string path;
		
		path = get_cmd_path ("exo-open");
		if ((path != null)&&(path != "")){
			return execute_command_sync ("exo-open " + double_quote (txt));
		}

		path = get_cmd_path ("nemo");
		if ((path != null)&&(path != "")){
			return execute_command_sync ("nemo " + double_quote (txt));
		}
		
		path = get_cmd_path ("nautilus");
		if ((path != null)&&(path != "")){
			return execute_command_sync ("nautilus " + double_quote (txt));
		}
		
		path = get_cmd_path ("thunar");
		if ((path != null)&&(path != "")){
			return execute_command_sync ("thunar " + double_quote (txt));
		}

		return -1;
	}

	public int chmod (string file, string permission)
	{
		return execute_command_sync ("chmod " + permission + " " + double_quote (file));
	}
	
	public int process_pause (Pid procID)
	{
		return execute_command_sync ("kill -STOP " + procID.to_string());
	}
	
	public int process_resume (Pid procID)
	{
		return execute_command_sync ("kill -CONT " + procID.to_string());
	}

	public int notify_send (string title, string message, int durationMillis, string urgency)
	{
		string s = "notify-send -t %d -u %s -i %s \"%s\" \"%s\"".printf(durationMillis, urgency, Gtk.Stock.INFO, title, message);
		return execute_command_sync (s);
	}
	
	public string get_cmd_path (string cmd)
	{
		try {
			int exitCode;
			string stdout, stderr;
			Process.spawn_command_line_sync("which " + cmd, out stdout, out stderr, out exitCode);
	        return stdout;
		}
		catch (Error e){
	        log_error (e.message);
	        return "";
	    }
	}
	
	public void do_events ()
    {
		while(Gtk.events_pending ())
			Gtk.main_iteration ();
	}
}

public class CellRendererProgress2 : Gtk.CellRendererProgress
{
	public override void render (Cairo.Context cr, Gtk.Widget widget, Gdk.Rectangle background_area, Gdk.Rectangle cell_area, Gtk.CellRendererState flags) 
	{
		
		if (text == "--") 
			return;
			
        int diff = (int) ((cell_area.height - height)/2);
        
        // Apply the new height into the bar, and center vertically:
        Gdk.Rectangle new_area = Gdk.Rectangle() ;
        new_area.x = cell_area.x;
        new_area.y = cell_area.y + diff;
        new_area.width = width - 5;
        new_area.height = height;
        
        base.render(cr, widget, background_area, new_area, flags);
	}
} 
