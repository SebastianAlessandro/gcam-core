/*! 
* \file LoggerFactory.cpp
* \ingroup CIAM
* \brief LoggerFactory class source file.
* \author Josh Lurz
* \date $Date$
* \version $Revision$
*/

#include "Definitions.h"
#include <string>
#include <map>
#include <cassert>

// xerces xml headers
#include <xercesc/parsers/XercesDOMParser.hpp>
#include <xercesc/dom/DOM.hpp>
#include <xercesc/sax/HandlerBase.hpp>
#include <xercesc/util/XMLString.hpp>
#include <xercesc/util/PlatformUtils.hpp>
#include "xmlHelper.h"
// end of xerces headers

#include "LoggerFactory.h"
#include "Logger.h"

// Logger subclass headers.
#include "PlainTextLogger.h"
#include "XMLLogger.h"

using namespace std;
using namespace xercesc;

map<string,Logger*> LoggerFactory::loggers;

//! Parse the XML data.
void LoggerFactory::XMLParse( const DOMNode* root ) {
	DOMNode* curr = 0;
	DOMNodeList* nodeList;
	string loggerType;
	string nodeName;
	
	Logger* newLogger = 0;
	
	/*! \pre assume we were passed a valid node. */
	assert( root );
	
	// get the children of the node.
	nodeList = root->getChildNodes();
	
	// loop through the children
	for ( int i = 0; i < static_cast<int>( nodeList->getLength() ); i++ ){
		curr = nodeList->item( i );
		nodeName = XMLHelper<string>::safeTranscode( curr->getNodeName() );
		
		if( nodeName == "Logger" ) {
			// get the Logger type.
			loggerType = XMLHelper<string>::getAttrString( curr, "type" );
			
			// Add additional types here.
			if( loggerType == "PlainTextLogger" ){
				newLogger = new PlainTextLogger();
			}
			else if( loggerType == "XMLLogger" ){
				newLogger = new XMLLogger();
			}
			else {
				newLogger = new PlainTextLogger();
			}
			
			newLogger->XMLParse( curr );
			newLogger->open();
			loggers[ newLogger->name ] = newLogger;
		}
	}
}

//! Returns the instance of the Logger, creating it if neccessary.
Logger* LoggerFactory::getLogger( const string& loggerName ) {
	map<string,Logger*>::const_iterator logIter = loggers.find( loggerName );
	
	if( logIter != loggers.end() ) {
		return logIter->second;
	}
	else {
		cout << "Creating uninitialized logger." << endl;
		Logger* newLogger = new PlainTextLogger( loggerName );
		newLogger->open();
		loggers[ loggerName ] = newLogger;
		return newLogger;
	}
}

//! Cleans up the logger.
void LoggerFactory::cleanUp() {
	for( map<string,Logger*>::iterator logIter = loggers.begin(); logIter != loggers.end(); logIter++ ){
		logIter->second->close();
		delete logIter->second;
	}
	loggers.clear();
	
}

void LoggerFactory::toDebugXML( ostream& out ) const {
	
	// write out the root tag.
	out << "<LoggerFactory>" << endl;

	// increase the indent.
	Tabs::increaseIndent();

	for( map<string,Logger*>::const_iterator logIter = loggers.begin(); logIter != loggers.end(); logIter++ ){
		logIter->second->toDebugXML( out );
	}
	
	// decrease the indent.
	Tabs::decreaseIndent();
	
	// write the closing tag.
	Tabs::writeTabs( out );
	out << "</LoggerFactory>" << endl;
}

