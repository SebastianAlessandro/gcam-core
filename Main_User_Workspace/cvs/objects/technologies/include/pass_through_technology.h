#ifndef _PASS_THROUGH_TECHNOLOGY_H_
#define _PASS_THROUGH_TECHNOLOGY_H_
#if defined(_MSC_VER)
#pragma once
#endif

/*
 * LEGAL NOTICE
 * This computer software was prepared by Battelle Memorial Institute,
 * hereinafter the Contractor, under Contract No. DE-AC05-76RL0 1830
 * with the Department of Energy (DOE). NEITHER THE GOVERNMENT NOR THE
 * CONTRACTOR MAKES ANY WARRANTY, EXPRESS OR IMPLIED, OR ASSUMES ANY
 * LIABILITY FOR THE USE OF THIS SOFTWARE. This notice including this
 * sentence must appear on any copies of this computer software.
 *
 * EXPORT CONTROL
 * User agrees that the Software will not be shipped, transferred or
 * exported into any country or used in any manner prohibited by the
 * United States Export Administration Act or any other applicable
 * export laws, restrictions or regulations (collectively the "Export Laws").
 * Export of the Software may require some form of license or other
 * authority from the U.S. Government, and failure to obtain such
 * export control license may result in criminal liability under
 * U.S. laws. In addition, if the Software is identified as export controlled
 * items under the Export Laws, User represents and warrants that User
 * is not a citizen, or otherwise located within, an embargoed nation
 * (including without limitation Iran, Syria, Sudan, Cuba, and North Korea)
 *     and that User is not otherwise prohibited
 * under the Export Laws from receiving the Software.
 *
 * Copyright 2011 Battelle Memorial Institute.  All Rights Reserved.
 * Distributed as open-source under the terms of the Educational Community
 * License version 2.0 (ECL 2.0). http://www.opensource.org/licenses/ecl2.php
 *
 * For further details, see: http://www.globalchange.umd.edu/models/gcam/
 *
 */


/*!
 * \file pass_through_technology.h
 * \ingroup Objects
 * \brief The PassThroughTechnology class header file.
 * \author Pralit Patel
 */
class IVisitor;

#include "technologies/include/technology.h"

/*!
 * \ingroup Objects
 * \brief A technology meant only to pass demands on to a pass-through sector.
 * \details This technology will look up how much fixed output there was in
 *          it's corresponding pass-though sector and report that as fixed
 *          to it's containing sector.  It will then pass along the total demand
 *          to the pass-through sector.
 *
 * \author Pralit Patel
 */
class PassThroughTechnology: public Technology
{
public:
    PassThroughTechnology( const std::string& aName, const int aYear );
    virtual ~PassThroughTechnology();

    static const std::string& getXMLNameStatic();

    // ITechnology methods
    virtual const std::string& getXMLName() const;

    virtual PassThroughTechnology* clone() const;

    virtual void completeInit( const std::string& aRegionName,
                               const std::string& aSectorName,
                               const std::string& aSubsectorName,
                               const IInfo* aSubsectorIInfo,
                               ILandAllocator* aLandAllocator );

    virtual void production( const std::string& aRegionName,
                             const std::string& aSectorName,
                             double aVariableDemand,
                             double aFixedOutputScaleFactor,
                             const GDP* aGDP,
                             const int aPeriod );

    virtual double getFixedOutput( const std::string& aRegionName,
                                   const std::string& aSectorName,
                                   const bool aHasRequiredInput,
                                   const std::string& aRequiredInput,
                                   const double aMarginalRevenue,
                                   const int aPeriod ) const;

protected:
    virtual bool XMLDerivedClassParse( const std::string& aNodeName, const xercesc::DOMNode* aNode );
    virtual void toInputXMLDerived( std::ostream& aOut, Tabs* aTabs ) const;
    virtual void toDebugXMLDerived( const int aPeriod, std::ostream& aout, Tabs* aTabs ) const;

private:
    //! The name of the sector this technology is retrieving fixed output from (extracted from the input objects).
    std::string mPassThroughSectorName;

    //! The market name in which mPassThroughSectorName exists (extracted from the input objects).
    std::string mPassThroughMarketName;

    //! The level of fixed output that exists in mPassThroughSectorName.
    double mPassThroughFixedOutput;
};

#endif // _PASS_THROUGH_TECHNOLOGY_H_

