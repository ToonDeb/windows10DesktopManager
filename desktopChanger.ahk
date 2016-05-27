class JPGIncDesktopManagerClass
{		
	_optionsMoveWindowHotkey := "moveWindowModKey"
	_optionsChangeVirtualDesktopHotkey := "goToDesktopModKey"
	
	goToDesktopCallbackFunctionName := "goToDesktop"
	moveActiveWindowToDesktopFunctionName := "moveActiveWindowToDesktop"
	
	__new(options := "") 
	{
		this.options := options
		this.desktopMapper := new DesktopMapperClass(new VirtualDesktopManagerClass())
		this.monitorMapper := new MonitorMapperClass()
		this.hotkeyManager := new JPGIncHotkeyManager(this)
		
		this._setupHotkeysFromOptions(options)
		return this
	}
	
	_setupHotkeysFromOptions(options) 
	{
		this.hotkeyManager.setupDefaultHotkeys()
		if(options[this._optionsMoveWindowHotkey])
		{
			this.hotkeyManager.moveWindowToDesktopHotkey(options[this._optionsMoveWindowHotkey])
		}
		if(options[this._optionsChangeVirtualDesktopHotkey])
		{
			this.hotkeyManager.goToDesktopHotkey(options[this._optionsChangeVirtualDesktopHotkey])
		}
		return this
	}
	
	/*
	 *	swap to the given virtual desktop number
	 */
	goToDesktop(newDesktopNumber) 
	{
		debugger("in go to desktop changing to " newDesktopNumber)
		this._makeDesktopsIfRequired(newDesktopNumber)
			._goToDesktop(newDesktopNumber)
			.closeMultitaskingViewFrame()
			.doPostMoveDesktop()
		return this
	}
	
	_makeDesktopsIfRequired(minimumNumberOfDesktops)
	{
		currentNumberOfDesktops := this.desktopMapper.getNumberOfDesktops()
		loop, % minimumNumberOfDesktops - currentNumberOfDesktops
		{
			this._send("#^d")
		}
		
		return this
	}
	
	/*
	 * If we send the keystrokes too quickly you sometimes get a flickering of the screen
	 */
	_send(toSend)
	{
		oldDelay := A_KeyDelay
		SetKeyDelay, 30
		
		send, % toSend
		
		SetKeyDelay, % oldDelay
		return this
	}

	_goToDesktop(newDesktopNumber)
	{
		currentDesktop := this.desktopMapper.getDesktopNumber()
		direction := currentDesktop - newDesktopNumber
		distance := Abs(direction)
		debugger("distance to move is " distance "`ndirectin" direction)
		if(direction < 0)
		{
			debugger("Sending right! " distance "times")
			this._send("^#{right " distance "}")
		} else
		{
			this._send("^#{left " distance "}")
		}
		return this
	}
	
	closeMultitaskingViewFrame()
	{
		IfWinActive, ahk_class MultitaskingViewFrame
		{
			this._send("#{tab}")
		}
		return this
	}
	
	openMultitaskingViewFrame()
	{
		IfWinNotActive, ahk_class MultitaskingViewFrame
		{
			this._send("#{tab}")
			WinWaitActive, ahk_class MultitaskingViewFrame
		}
		return this
	}
	
	doPostMoveDesktop() 
	{
		this._callFunction(this.options.postChangeDesktop)
		return this
	}
	
	doPostMoveWindow() 
	{
		this._callFunction(this.options.postMoveWindow)
		return this
	}
	
	_callFunction(possibleFunction)
	{
		if(IsFunc(possibleFunction)) 
		{
			%possibleFunction%()
		} else if(IsObject(possibleFunction))
		{
			possibleFunction.Call()
		} else if(IsLabel(possibleFunction))
		{
			gosub, % possibleFunction
		}
		return this
	}
	
	moveActiveWindowToDesktop(targetDesktop, follow := false)
	{
		currentDesktop := this.desktopMapper.getDesktopNumber()
		if(currentDesktop == targetDesktop) 
		{
			return this
		}
		numberOfTabsNeededToSelectActiveMonitor := this.monitorMapper.getRequiredTabCount(WinActive("A"))
		numberOfDownsNeededToSelectDesktop := this.getNumberOfDownsNeededToSelectDesktop(targetDesktop, currentDesktop)
		
		this.openMultitaskingViewFrame()
			._send("{tab " numberOfTabsNeededToSelectActiveMonitor "}")
			._send("{Appskey}m{Down " numberOfDownsNeededToSelectDesktop "}{Enter}")
			.closeMultitaskingViewFrame()
			.doPostMoveWindow()
		
		return	this
	}
	
	getNumberOfDownsNeededToSelectDesktop(targetDesktop, currentDesktop)
	{
		; This part figures out how many times we need to push down within the context menu to get the desktop we want.	
		if (targetDesktop > currentDesktop)
		{
			targetDesktop -= 2
		}
		else
		{
			targetdesktop--
		}
		return targetDesktop
	}
	
	getIndexFromArray(searchFor, array) 
	{
		loop, % array.MaxIndex()
		{
			if(array[A_index] == searchFor) 
			{
				return A_index
			}
		}
		return false
	}
}