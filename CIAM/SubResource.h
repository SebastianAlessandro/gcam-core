#ifndef _SUBRSRC_H_
#define _SUBRSRC_H_
#if defined(_MSC_VER)
#pragma once
#endif

/*! 
* \file SubResource.h
* \ingroup CIAM
* \brief The SubResource class header file.
* \author Sonny Kim
* \date $Date$
* \version $Revision$
*/
#include <xercesc/dom/DOM.hpp>

// Forward declaration.
class Grade;

/*! 
* \ingroup CIAM
* \brief SubResource is a class that contains grades.
* \author Sonny Kim
*/

class SubResource
{
protected:
   
   std::string name; //!< SubResource name
   int nograde; //!< number of grades of each SubResource
   double priceElas; //!< price elasticity for short-term supply limit
   double minShortTermSLimit; //!< short-term supply limit.
   std::vector<double> rscprc; //!< subresource price
   std::vector<double> techChange; //!< technical change
   std::vector<double> environCost; //!< Environmental costs
   std::vector<double> severanceTax; //!< Severence Tax (exogenous)
   std::vector<double> available; //!< total available resource
   std::vector<double> annualprod; //!< annual production of SubResource
   std::vector<double> cumulprod; //!< cumulative production of SubResource
   std::vector<double> gdpExpans; //!< short-term supply limit expansion elasticity w/ gdp
   std::vector<double> scaleFactor; //!< Knob to control regional resource production. Default == 1.
   std::vector<double> cumulativeTechChange; //!< Cumulative Technical Change for this sub-sector
   // Cumulative technical change needs to be in sub-resource sector 
   std::vector<Grade*> grade; //!< amount of SubResource for each grade
   std::map<std::string,int> gradeNameMap; //!< Map of grade name to integer position in vector. 
   
public:
   SubResource();
   virtual ~SubResource();
   virtual std::string getType() const = 0;
   void clear();
   std::string getName() const;
   void XMLParse( const xercesc::DOMNode* tempnode );
   void completeInit();
   virtual void XMLDerivedClassParse( const std::string nodeName, const xercesc::DOMNode* node ) = 0; 
   virtual void initializeResource(); 
   void toXML( std::ostream& out ) const;
   virtual void toXMLforDerivedClass( std::ostream& out ) const;
   void toOutputXML( std::ostream& out ) const;
   void toDebugXML( const int period, std::ostream& out ) const;
   virtual void cumulsupply(double prc,int per);
   double getPrice(int per);
   double getCumulProd(int per);
   virtual void annualsupply(int per,double gnp1,double gnp2,double price1,double price2);
   double getAnnualProd(int per);
   double getAvailable(int per);
   int getMaxGrade();
   void MCoutput( const std::string& regname, const std::string& secname); 
   void outputfile(const std::string &regname, const std::string& sname); 
   void updateAvailable( const int period );
};


/*! 
* \ingroup CIAM
* \brief A class which defines a SubDepletableResource object, which is a container for multiple grade objects.
* \author Steve Smith
* \date $ Date $
* \version $ Revision $
*/
class SubDepletableResource: public SubResource {
   virtual std::string getType() const;
   virtual void XMLDerivedClassParse( const std::string nodeName, const xercesc::DOMNode* node );
};

/*! 
* \ingroup CIAM
* \brief A class which defines a SubFixedResource object, which is a container for multiple grade objects.
* \author Steve Smith
* \date $ Date $
* \version $ Revision $
*/
class SubFixedResource: public SubResource {
   virtual std::string getType() const;
   virtual void XMLDerivedClassParse( const std::string nodeName, const xercesc::DOMNode* node );
};

#endif // _SUBRSRC_H_
